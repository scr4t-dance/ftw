import React, { useState, } from 'react';

import { useQueries, useQueryClient } from "@tanstack/react-query";
import { Controller, useForm, type UseFormReturn } from "react-hook-form";

import {
    RoleItem,
    type Bib,
} from "@hookgen/model";
import type { BibList, CompetitionId, CouplesHeatsArray, CoupleTarget, DancerId, HeatsArray, OldBibNewBib, Panel, PhaseId, SinglesHeat, SinglesHeatsArray, SingleTarget, Target } from "@hookgen/model";
import {
    useGetApiPhaseIdCouplesHeats,
    useGetApiPhaseIdHeats,
    useGetApiPhaseIdSinglesHeats,
} from '~/hookgen/heat/heat';

import { BareBibListComponent, BibRowReadOnly, dancerArrayFromTarget, DancerCell, get_bibs, } from '@routes/bib/BibComponents';
import { Field } from "@routes/index/field";
import { getGetApiCompIdBibsQueryKey, useDeleteApiCompIdBib, usePatchApiCompIdBib, usePutApiCompIdBib } from '~/hookgen/bib/bib';
import { get_follower_from_bib, get_leader_from_bib, SelectCoupleTargetForm, SelectSingleTargetForm, type BibCoupleTargetForm, type BibSingleTargetForm } from '../bib/NewBibFormComponent';


type BibPairingRowEditableProps = {
    formObject: UseFormReturn<OldBibNewBib, any, OldBibNewBib>;
    missingBibList: BibList;
    onUpdate: () => void;
    onCancel: () => void;
    error: string | undefined;
    success: string | undefined;
};


function BibPairingRowEditable({ formObject, missingBibList, onUpdate, onCancel, error, success }: BibPairingRowEditableProps) {
    const {
        register,
        formState: { errors, },
        watch
    } = formObject;

    const targetType = watch("new_bib.target.target_type");

    return (
        <>
            <td>
                {targetType}
                {error &&
                    <p>
                        {error}
                    </p>
                }
                {success &&
                    <p>
                        {success}
                    </p>
                }
            </td>

            <td>
                <Field label="Dossard" error={errors?.new_bib?.bib?.message}>
                    <input type="number" {...register("new_bib.bib", {
                        valueAsNumber: true,
                        required: true,
                        min: {
                            value: 0,
                            message: "Le numéro de dossard doit être un entier positif.",
                        },
                        validate: {
                            checkUniqueness: (bib) => {
                                return !missingBibList.bibs.map((b) => b.bib).includes(bib) || `Bib ${bib} is already taken`
                            },
                        }
                    })}
                    />
                </Field>
            </td>

            {targetType === "single" && (
                <>
                    <td><DancerCell id_dancer={formObject.getValues("new_bib.target.target")} /></td>
                    <td>{formObject.getValues("new_bib.target.role")?.join(", ")}</td>
                </>
            )}

            {targetType === "couple" && (
                <>
                    <td>
                        <p>{RoleItem.Follower}</p>
                        <p>{RoleItem.Leader}</p>
                    </td>
                    <td>
                        <DancerCell id_dancer={formObject.getValues("new_bib.target.follower")} />
                        <DancerCell id_dancer={formObject.getValues("new_bib.target.leader")} />
                    </td>
                </>
            )}
            <td>
                <button type="button" onClick={() => onUpdate()}>Màj</button>
                <button type="button" onClick={() => onCancel()} >Annuler</button>
            </td>
        </>
    );
}

function EditablePairingTarget({ bib, missingBibList }: { bib: Bib, missingBibList: BibList }) {

    const id_competition = bib.competition;

    const [isEditing, setIsEditing] = useState(false);

    const formObject = useForm<OldBibNewBib>({
        defaultValues: { old_bib: bib, new_bib: bib },
    });

    const {
        handleSubmit,
        reset,
        setError,
    } = formObject;

    const queryClient = useQueryClient();

    const { mutate: addTargetToHeat, error, isError, isSuccess } = usePatchApiCompIdBib({
        mutation: {
            onSuccess: () => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiCompIdBibsQueryKey(id_competition),
                });
                setIsEditing(false);
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
                setError("root.serverError", { message: 'Erreur lors de l’ajout de la compétition.' });
            }
        }
    });

    const { mutate: deleteTargetFromHeat } = useDeleteApiCompIdBib({
        mutation: {
            onSuccess: () => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiCompIdBibsQueryKey(id_competition),
                });
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
                setError("root.serverError", { message: err.message });
            }
        }
    });

    const handleUpdate = handleSubmit((data) => {
        if (data.old_bib.bib !== data.new_bib.bib) addTargetToHeat({ id: data.old_bib.competition, data });
        setIsEditing(false);
    });

    const handleCancel = () => {
        reset();
        setIsEditing(false);
    };

    const errorMessage = isError ? error.message : undefined;
    const successMessage = isSuccess ? "Bib correctly added" : undefined;

    return (
        <>
            {isEditing ? (
                <BibPairingRowEditable
                    formObject={formObject}
                    missingBibList={missingBibList}
                    onUpdate={handleUpdate}
                    onCancel={handleCancel}
                    error={errorMessage}
                    success={successMessage}
                />
            ) : (
                <BibRowReadOnly
                    bib_object={bib}
                    onEdit={() => setIsEditing(true)}
                    onDelete={() => deleteTargetFromHeat({ id: id_competition, data: bib })}
                />
            )
            }
        </>

    );
}

type NewPairingTargetProps = {
    id_competition: CompetitionId,
    existingBibList: BibList,
    missingBibList: BibList
};

function NewPairingTarget({ id_competition, existingBibList, missingBibList }: NewPairingTargetProps) {

    const follower_select_bibs_list = missingBibList.bibs.map(
        (b) => get_follower_from_bib(b, (bib: Bib) => bib.bib.toString().concat(" "))
    ).filter((v) => v != null);
    const leader_select_bibs_list = missingBibList.bibs.map(
        (b) => get_leader_from_bib(b, (bib: Bib) => bib.bib.toString().concat(" "))
    ).filter((v) => v != null);

    const defaultTarget = {
        target_type: "couple",
        leader: -1,
        follower: -1,
    };
    const formObject = useForm<Bib>({
        defaultValues: { competition: id_competition, bib: 0, target: defaultTarget } as Bib,
    });

    const {
        handleSubmit,
        watch,
        setError,
        reset,
        register,
        formState: { errors, defaultValues, isSubmitSuccessful }
    } = formObject;

    const queryClient = useQueryClient();

    const { mutate: addTargetToBibs, isError, error } = usePutApiCompIdBib({
        mutation: {
            onSuccess: (_, { id: id_competition }) => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiCompIdBibsQueryKey(id_competition),
                });
                reset();
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
                setError("root.serverError", { message: "Erreur lors de l'ajout de la nouvelle target dans les pairings" });
            }
        }
    });

    const targetType = watch("target.target_type");

    const handleUpdate = handleSubmit((data) => {
        console.log("submit", data);
        if (JSON.stringify(data.target) === JSON.stringify(defaultValues?.target)) {
            setError("root.formValidation", { message: "Cannot be default" });
            return;
        }
        if (data.target.target_type === "couple" && data.target.follower === -1) {
            setError("root.formValidation", { message: "Follower must be set" });
            return;
        }
        if (data.target.target_type === "couple" && data.target.leader === -1) {
            setError("root.formValidation", { message: "Leader must be set" });
            return;
        }
        addTargetToBibs({ id: id_competition, data });
    });

    return (
        <tr>
            <td>
                {targetType}
            </td>


            <td>
                <Field label="" error={errors.bib?.message}>
                    <input type="number" {...register("bib", {
                        valueAsNumber: true,
                        required: true,
                        min: {
                            value: 0,
                            message: "Le numéro de dossard doit être un entier positif.",
                        },
                        validate: {
                            checkUniqueness: (b) => !existingBibList.bibs.map((b) => b.bib).includes(b) || `Bib ${b} already already exist`
                        }
                    })}
                    />
                </Field>
            </td>

            <td>
                {isError &&
                    <p>
                        {error.message}
                    </p>
                }
                {errors.root?.formValidation &&
                    <div className="error_message">⚠️ {errors.root.formValidation.message}</div>
                }

                {errors.root?.serverError &&
                    <div className="error_message">⚠️ {errors.root.serverError.message}</div>
                }

                {isSubmitSuccessful &&
                    <p>
                        Bib correctly added
                    </p>
                }
            </td>

            <td>
                {targetType === "couple" &&
                    <Field label="" error={errors.target?.message}>
                        <SelectCoupleTargetForm
                            formObject={formObject as BibCoupleTargetForm}
                            follower_id_list={follower_select_bibs_list}
                            leader_id_list={leader_select_bibs_list} />
                    </Field>
                }
                {targetType === "single" &&
                    <Field label="" error={errors.target?.message}>
                        <SelectSingleTargetForm
                            formObject={formObject as BibSingleTargetForm}
                            follower_id_list={follower_select_bibs_list}
                            leader_id_list={leader_select_bibs_list} />
                    </Field>
                }

            </td>

            <td>
                <button type="submit" onClick={() => handleUpdate()}>Add new</button>
            </td>
        </tr>
    );
}

export function BibPairingListComponent({ bib_list, id_competition, otherTargetTypeBibList }: { bib_list: BibList, id_competition: CompetitionId, otherTargetTypeBibList: BibList }) {

    function getTargetKey(bib: Bib) {
        return bib.target.target_type === "single" ?
            String(bib.target.role).concat("*", String(bib.target.target))
            : String(bib.target.follower).concat("-", String(bib.target.leader));
    }

    return (
        <>
            <table>
                <tbody>
                    <tr>
                        <th>Type target</th>
                        <th>Bib</th>
                        <th>Rôle</th>
                        <th>Target</th>
                        <th>Action</th>
                    </tr>

                    {bib_list.bibs.map((bibObject, index) => (
                        <tr key={`${bibObject.competition}-${bibObject.target.target_type}-${getTargetKey(bibObject)}`}
                            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>

                            <EditablePairingTarget
                                missingBibList={otherTargetTypeBibList}
                                bib={bibObject}
                            />
                        </tr>
                    ))}
                    <NewPairingTarget
                        id_competition={id_competition}
                        existingBibList={bib_list}
                        missingBibList={otherTargetTypeBibList} />
                </tbody>
            </table>
        </>
    );
}


export function PairingComponent({ id_competition: id_competition, panel_data, id_phase, previous_id_phase, dataBibs }: { id_competition: CompetitionId, panel_data: Panel, id_phase: PhaseId, previous_id_phase: PhaseId, dataBibs: BibList }) {


    const [showPreviousPhaseBibs, toggleBibView] = useState(false);
    const { data: previousPhaseHeats, isSuccess } = useGetApiPhaseIdHeats(previous_id_phase);
    const { data: singlesHeats, isSuccess: isSuccessSingles } = useGetApiPhaseIdSinglesHeats(id_phase);
    const { data: couplesHeats, isSuccess: isSuccessCouples } = useGetApiPhaseIdCouplesHeats(id_phase);

    if (!isSuccess) return <p>Loading heats...</p>;
    if (!isSuccessSingles) return <p>Loading singles heats...</p>;
    if (!isSuccessCouples) return <p>Loading couples heats...</p>;

    const otherTargetTypeBibList = { bibs: dataBibs.bibs.filter((b) => b.target.target_type !== panel_data.panel_type) };
    const sameTargetTypeBibList = { bibs: dataBibs.bibs.filter((b) => b.target.target_type === panel_data.panel_type) };

    function get_heat_targets(heats: HeatsArray) {
        return heats.heat_type === "couple" ?
            heats.heats.flatMap(h => h.couples) :
            (heats as SinglesHeatsArray).heats.flatMap((h) => (
                h.leaders.concat(h.followers)
            ));
    }

    const heatsZeroTarget: Target[] = previousPhaseHeats.heat_type === 'couple' ?
        get_heat_targets(couplesHeats)
        : get_heat_targets(singlesHeats);

    const heatsT = get_heat_targets(previousPhaseHeats)
        .filter(t => !heatsZeroTarget.some(tt => JSON.stringify(tt) === JSON.stringify(t)));
    const heatsTarget = showPreviousPhaseBibs
        ? [...heatsZeroTarget, ...heatsT]
        : [...heatsZeroTarget]; // force new array reference

    const previousPhaseBibList: BibList = get_bibs(otherTargetTypeBibList, heatsTarget);

    console.log("singlesHeats", singlesHeats, "previosuPhaseBibList", previousPhaseBibList, "sameTargetTypeBibList", sameTargetTypeBibList);

    const includedBibList: DancerId[] = sameTargetTypeBibList.bibs.flatMap((sb) => dancerArrayFromTarget(sb.target));
    const unmatchedPreviousPhaseBibList: BibList = {
        bibs: previousPhaseBibList.bibs.filter((b) => !dancerArrayFromTarget(b.target).some((id_d) => includedBibList.includes(id_d)))
    }

    //if (panel_data.panel_type !== previousPhaseHeats.heat_type) return <p>Panel {panel_data.panel_type} != Heats {previousPhaseHeats.heat_type} </p>;

    //console.log("heat_type ", previousPhaseHeats.heat_type, "bibHeats", heatsTarget, "missing_bibs", previousPhaseBibList, "sameTargetTypeDataBibs", otherTargetTypeBibList);

    return (
        <>
            <button type='button' onClick={() => toggleBibView(!showPreviousPhaseBibs)}>Toggle View Previous Phase bibs</button>
            <p>state {String(showPreviousPhaseBibs)}</p>
            <h1>Pairings</h1>
            {panel_data.panel_type === "couple" &&
                <>
                    <h3>Couples</h3>
                    <BibPairingListComponent bib_list={sameTargetTypeBibList}
                        otherTargetTypeBibList={previousPhaseBibList}
                        id_competition={id_competition}
                    />
                </>
            }
            {panel_data.panel_type === "single" &&
                <p>to be implemented for single panels. Are you sure judges are correctly configured?</p>
            }

            <h3>Unmatched bibs of previous phase</h3>
            <BareBibListComponent bib_list={unmatchedPreviousPhaseBibList.bibs} />
        </>
    );
}
