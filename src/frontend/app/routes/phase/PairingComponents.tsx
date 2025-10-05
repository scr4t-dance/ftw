import React, { useState, } from 'react';

import { useQueryClient } from "@tanstack/react-query";
import { Controller, useForm, type UseFormReturn } from "react-hook-form";

import {
    type Bib,
} from "@hookgen/model";
import type { BibList, CompetitionId, CoupleTarget, Panel, PhaseId, SinglesHeat, Target } from "@hookgen/model";
import {
    useGetApiPhaseIdHeats,
} from '~/hookgen/heat/heat';

import { BareBibListComponent, BibRowReadOnly, DancerCell, get_bibs, } from '@routes/bib/BibComponents';
import { Field } from "@routes/index/field";
import { getGetApiCompIdBibsQueryKey, useDeleteApiCompIdBib, usePutApiCompIdBib } from '~/hookgen/bib/bib';


type BibCoupleTargetForm = UseFormReturn<Bib & { target: CoupleTarget }, any, Bib & { target: CoupleTarget }>;

interface SelectCoupleTargetFormProps {
    formObject: BibCoupleTargetForm,
    select_bibs_list: BibList,
}

export function SelectCoupleTargetForm({ formObject, select_bibs_list }: SelectCoupleTargetFormProps) {

    const {
        control,
        watch,
        formState: { errors, defaultValues },
    } = formObject;

    const follower_select_bibs_list = select_bibs_list.bibs.map(
        (b) => b.target.target_type === "single" && b.target.role[0] === "Follower" ? b.target.target : undefined
    ).filter((v) => v != null);
    const leader_select_bibs_list = select_bibs_list.bibs.map(
        (b) => b.target.target_type === "single" && b.target.role[0] === "Leader" ? b.target.target : undefined
    ).filter((v) => v != null);

    const target_type = watch("target.target_type");

    return (
        <>
            {target_type === "couple" &&
                <>
                    <Field label="Follower" error={errors.target?.follower?.message}>
                        <Controller
                            control={control}
                            name={"target.follower"}
                            render={({ field }) => (
                                <select
                                    onChange={(e) => {
                                        const index = Number(e.target.value);
                                        const selected = {
                                            ...e,
                                            target: {
                                                ...e.target,
                                                value: follower_select_bibs_list[index],
                                            }
                                        };
                                        field.onChange(selected);
                                    }}
                                >
                                    <option key={-1} value={-1}>----</option>
                                    {follower_select_bibs_list.map((id_dancer, index) => (
                                        <option key={index} value={index}>{id_dancer}</option>)
                                    )}
                                </select>
                            )}
                        />
                    </Field>

                    <Field label="Leader" error={errors.target?.leader?.message}>
                        <Controller
                            control={control}
                            name={"target.leader"}
                            render={({ field }) => (
                                <select
                                    onChange={(e) => {
                                        const index = Number(e.target.value);
                                        const selected = {
                                            ...e,
                                            target: {
                                                ...e.target,
                                                value: leader_select_bibs_list[index],
                                            }
                                        };
                                        field.onChange(selected);
                                    }}
                                >
                                    <option key={-1} value={-1}>----</option>
                                    {leader_select_bibs_list.map((id_dancer, index) => (
                                        <option key={index} value={index}>{id_dancer}</option>)
                                    )}
                                </select>
                            )}
                        />
                    </Field>

                </>
            }
        </>
    );
}

type BibPairingRowEditableProps = {
    formObject: UseFormReturn<Bib, any, Bib>;
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

    const targetType = watch("target.target_type");

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
                <Field label="Dossard" error={errors.bib?.message}>
                    <input type="number" {...register("bib", {
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
                    <td><DancerCell id_dancer={formObject.getValues("target.target")} /></td>
                    <td>{formObject.getValues("target.role")?.join(", ")}</td>
                </>
            )}

            {targetType === "couple" && (
                <>
                    <SelectCoupleTargetForm formObject={formObject as BibCoupleTargetForm} select_bibs_list={missingBibList} />
                    <td>
                        <DancerCell id_dancer={formObject.getValues("target.follower")} />
                        <DancerCell id_dancer={formObject.getValues("target.leader")} />
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

function EditablePairingTarget({ bib, index, missingBibList }: { bib: Bib, index: number, missingBibList: BibList }) {

    const id_competition = bib.competition;

    const [isEditing, setIsEditing] = useState(false);

    const formObject = useForm<Bib>({
        defaultValues: bib,
    });

    const {
        handleSubmit,
        reset,
        setError,
    } = formObject;

    const queryClient = useQueryClient();

    const { mutate: addTargetToHeat, error, isError, isSuccess } = usePutApiCompIdBib({
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
        addTargetToHeat({ id: data.competition, data });
    });

    const handleCancel = () => {
        reset();
        setIsEditing(false);
    };

    const errorMessage = isError ? error.message : undefined;
    const successMessage = isSuccess ? "Bib correctly added" : undefined;

    return (
        <tr key={`${bib.competition}-${bib.target.target_type}-${index}`}
            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>

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
        </tr >

    );
}

function NewPairingTarget({ id_competition, defaultBib, missingBibList }: { id_competition: CompetitionId, defaultBib: Bib, missingBibList: BibList }) {

    const formObject = useForm<Bib>({
        defaultValues: { competition: id_competition, bib: 0, target: defaultBib.target } as Bib,
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
                setError("root.serverError", { message: 'Erreur lors de l’ajout de la compétition.' });
            }
        }
    });

    const targetType = watch("target.target_type");

    const handleUpdate = handleSubmit((data) => {
        console.log("submit", data);
        if (JSON.stringify(data.target) === JSON.stringify(defaultValues?.target)) {
            setError("root.serverError", { message: "Cannot be default" });
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
                    })}
                    />
                </Field>
            </td>

            <td>
                <Field label="" error={errors.target?.message}>
                    <SelectCoupleTargetForm formObject={formObject as BibCoupleTargetForm} select_bibs_list={missingBibList} />
                </Field>
            </td>

            <td>
                {isError &&
                    <p>
                        {error.message}
                    </p>
                }
                {isSubmitSuccessful &&
                    <p>
                        Bib correctly added
                    </p>
                }
            </td>

            <td>
                <button type="submit" onClick={() => handleUpdate()}>Add new</button>
            </td>
        </tr>
    );
}

export function BibPairingListComponent({ bib_list, id_competition, otherTargetTypeBibList, defaultTarget }: { bib_list: Bib[], id_competition: CompetitionId, otherTargetTypeBibList: BibList, defaultTarget: Target }) {

    const defaultBib = {
        competition: id_competition,
        target: defaultTarget,
        bib: 0,
    } as Bib;

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

                    {bib_list.map((bibObject, index) => (
                        <EditablePairingTarget
                            missingBibList={otherTargetTypeBibList}
                            bib={bibObject}
                            index={index} />
                    ))}
                    <NewPairingTarget id_competition={id_competition} defaultBib={defaultBib} missingBibList={otherTargetTypeBibList} />
                </tbody>
            </table>
        </>
    );
}


export function PairingComponent({ id_competition: id_competition, panel_data, previous_id_phase, dataBibs }: { id_competition: CompetitionId, panel_data: Panel, previous_id_phase: PhaseId, dataBibs: BibList }) {

    const { data: previousPhaseHeats, isSuccess } = useGetApiPhaseIdHeats(previous_id_phase);

    const otherTargetTypeBibList = { bibs: dataBibs.bibs.filter((b) => b.target.target_type !== panel_data.panel_type) };
    const sameTargetTypeBibList = { bibs: dataBibs.bibs.filter((b) => b.target.target_type === panel_data.panel_type) };

    const heatsTarget: Target[] = previousPhaseHeats?.heats ? (
        previousPhaseHeats.heat_type === 'couple' ?
            previousPhaseHeats.heats.flatMap((h) => h.couples)
            : (previousPhaseHeats.heats as SinglesHeat[]).flatMap((h) => (
                h.leaders.concat(h.followers)
            ))
    ) : [];

    //const heatsBib = get_bibs(sameTargetTypeBibList, heatsTarget);

    const previousPhaseBibList: BibList = get_bibs(otherTargetTypeBibList, heatsTarget);

    if (!isSuccess) return <p>Loading heats...</p>;
    //if (panel_data.panel_type !== previousPhaseHeats.heat_type) return <p>Panel {panel_data.panel_type} != Heats {previousPhaseHeats.heat_type} </p>;

    //console.log("heat_type ", previousPhaseHeats.heat_type, "bibHeats", heatsTarget, "missing_bibs", previousPhaseBibList, "sameTargetTypeDataBibs", otherTargetTypeBibList);

    return (
        <>
            <h1>Pairings</h1>
            {panel_data.panel_type === "couple" &&
                <>
                    <h3>Couples</h3>
                    <BibPairingListComponent bib_list={sameTargetTypeBibList.bibs}
                        otherTargetTypeBibList={previousPhaseBibList}
                        id_competition={id_competition}
                        defaultTarget={{ target_type: "couple" } as Target}
                    />
                </>
            }
            {panel_data.panel_type === "single" &&
                <p>to be implemented for single panels. Are you sure judges are correctly configured?</p>
            }

            <h3>Previous bibs</h3>
            <BareBibListComponent bib_list={previousPhaseBibList.bibs} />
        </>
    );
}
