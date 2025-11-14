import React, { useState } from 'react';

import { useQueryClient } from "@tanstack/react-query";
import { Controller, useForm, type UseFormReturn } from "react-hook-form";

import {
    type Bib,
    type HeatTargetJudge, RoleItem,
} from "@hookgen/model";
import type { BibList, CompetitionId, CouplesHeat, HeatsArray, Panel, PhaseId, SinglesHeat, Target } from "@hookgen/model";
import {
    getGetApiPhaseIdHeatsQueryKey, useDeleteApiPhaseIdHeatTarget, useGetApiPhaseIdHeats, usePutApiPhaseIdHeatTarget
} from '~/hookgen/heat/heat';

import { BareBibListComponent, dancerArrayFromTarget, DancerCell, get_bibs, } from '@routes/bib/BibComponents';
import { Field } from "@routes/index/field";
import { useGetApiCompIdBibs } from '~/hookgen/bib/bib';
import { useGetApiPhaseIdJudges } from '~/hookgen/judge/judge';
import { InitHeatsWithBibForm, RandomizeHeatsForm } from './InitHeatsForm';


type HeatTargetRowReadOnlyProps = {
    heatTarget: HeatTargetJudge;
    bib: Bib;
    onDelete: () => void
};

function HeatTargetRowReadOnly({ heatTarget, bib, onDelete }: HeatTargetRowReadOnlyProps) {

    const dancer_list = dancerArrayFromTarget(heatTarget.target);
    return (
        <>
            <td>
                {heatTarget.target.target_type}
            </td>
            <td>{bib.bib}</td>

            <td>{heatTarget.target.target_type === "single" ?
                heatTarget.target.role :
                <> {RoleItem.Follower}
                    <br /> {RoleItem.Leader}
                </>
            }</td>
            <td>
                {dancer_list && dancer_list.map((i) => (
                    <DancerCell id_dancer={i} />
                ))
                }
            </td>
            <td>
                <button type="button" onClick={() => onDelete()}>
                    Delete
                </button>
            </td>
        </>

    );
}


function EditableHeatTarget({ heatTargetJudge, bib, index }: { heatTargetJudge: HeatTargetJudge, bib: Bib, index: number, }) {

    const defaultHeatTargetJudge = {
        ...heatTargetJudge,
        target: bib.target
    }

    const queryClient = useQueryClient();

    const { mutate: deleteTargetFromHeat } = useDeleteApiPhaseIdHeatTarget({
        mutation: {
            onSuccess: (id_phase) => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdHeatsQueryKey(id_phase),
                });
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
            }
        }
    });

    return (
        <tr key={`${defaultHeatTargetJudge.phase_id}-${defaultHeatTargetJudge.target.target_type}-${index}`}
            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>

            <HeatTargetRowReadOnly
                heatTarget={defaultHeatTargetJudge}
                bib={bib}
                onDelete={() => deleteTargetFromHeat({ id: defaultHeatTargetJudge.phase_id, data: defaultHeatTargetJudge })}
            />
        </tr >

    );
}

function NewHeatTarget({ defaultHeatTargetJudge, missingBibList }: { defaultHeatTargetJudge: HeatTargetJudge, missingBibList: BibList }) {
    const formObject = useForm<HeatTargetJudge>({
        defaultValues: defaultHeatTargetJudge
    });

    const {
        handleSubmit,
        control,
        watch,
        setError,
        reset,
        formState: { errors, defaultValues, isSubmitSuccessful }
    } = formObject;

    const queryClient = useQueryClient();

    const { mutate: addTargetToHeat, isError, error } = usePutApiPhaseIdHeatTarget({
        mutation: {
            onSuccess: (id_phase) => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdHeatsQueryKey(id_phase),
                });
                reset();
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
                setError("root.serverError", { message: 'Erreur lors de l’ajout de la compétition.' });
            }
        }
    });

    const handleUpdate = handleSubmit((data) => {
        console.log("submit", data);
        if (JSON.stringify(data.target) === JSON.stringify(defaultValues?.target)) {
            setError("root.formValidation", { message: "Cannot be default" });
            return;
        }
        addTargetToHeat({ id: data.phase_id, data });
    });

    const targetType = watch("target.target_type");

    return (
        <tr>
            <td>
                {targetType}
            </td>

            <td colSpan={2}>
                <Field label="" error={errors.target?.message}>
                    <Controller
                        control={control}
                        name={"target"}
                        render={({ field }) => (
                            <select
                                onChange={(e) => {
                                    const index = Number(e.target.value);
                                    console.log("onChange Target1", index);
                                    if (index === -1) {
                                        field.onChange({
                                            ...e,
                                            target: {
                                                ...e.target,
                                                value: defaultValues?.target
                                            }
                                        });
                                        return;
                                    }
                                    const selected = {
                                        ...e,
                                        target: {
                                            ...e.target,
                                            value: missingBibList.bibs[index].target
                                        }
                                    };
                                    console.log("onChange Target", index, selected);
                                    field.onChange(selected);
                                }}
                            >
                                <option key={-1} value={-1}>----</option>
                                {missingBibList.bibs.map((bib, index) => (
                                    <option key={index} value={index}>{bib.bib}</option>)
                                )}
                            </select>
                        )}
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
                <button type="submit" onClick={() => handleUpdate()}>Add new</button>
            </td>
        </tr>
    );
}

export function BibHeatListComponent({ bib_list, id_phase, heat_number, missingBibList, defaultTarget }: { bib_list: Bib[], id_phase: PhaseId, heat_number: number, missingBibList: BibList, defaultTarget: Target }) {

    const defaultHeatTarget = {
        phase_id: id_phase, heat_number: heat_number, target: defaultTarget,
        judge: -1,
        description: {
            artefact: "ranking",
            artefact_data: null,
        }
    } as HeatTargetJudge;

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
                        <EditableHeatTarget
                            heatTargetJudge={defaultHeatTarget}
                            bib={bibObject}
                            index={index} />
                    ))}
                    <NewHeatTarget defaultHeatTargetJudge={defaultHeatTarget} missingBibList={missingBibList} />
                </tbody>
            </table>
        </>
    );
}


type SingleHeatProps = {
    heat: SinglesHeat, dataBibs: BibList,
    heat_number: number,
    id_phase: number,
}

export function SingleHeatTable({ heat, dataBibs, heat_number, id_phase }: SingleHeatProps) {

    const followers = get_bibs(dataBibs, heat.followers);
    const leaders = get_bibs(dataBibs, heat.leaders);
    const notInHeatFollowerBibs = {
        bibs: dataBibs.bibs
            .filter((b) => (b.target.target_type === "single" && b.target.role[0] === "Follower"
                && !followers.bibs.map((hb) => hb.bib).includes(b.bib)
            ))
    } as BibList;
    const notInHeatLeaderBibs = {
        bibs: dataBibs.bibs
            .filter((b) => (b.target.target_type === "single" && b.target.role[0] === "Leader"
                && !leaders.bibs.map((hb) => hb.bib).includes(b.bib)
            ))
    } as BibList;

    return (
        <>
            <div>
                <h3>Followers</h3>
                <BibHeatListComponent bib_list={followers.bibs}
                    heat_number={heat_number} missingBibList={notInHeatFollowerBibs}
                    id_phase={id_phase}
                    defaultTarget={{ target_type: "single", role: ["Follower"] } as Target}
                />
            </div>
            <div>
                <h3>Leaders</h3>
                <BibHeatListComponent bib_list={leaders.bibs}
                    heat_number={heat_number} missingBibList={notInHeatLeaderBibs}
                    id_phase={id_phase}
                    defaultTarget={{ target_type: "single", role: ["Leader"] } as Target}
                />
            </div>
        </>);
}

type CoupleHeatTableProps = {
    heat: CouplesHeat, dataBibs: BibList,
    heat_number: number,
    id_phase: number,
}

export function CoupleHeatTable({ heat, dataBibs, heat_number, id_phase }: CoupleHeatTableProps) {


    const couples = get_bibs(dataBibs, heat.couples);
    const missingBibList = {
        bibs: dataBibs.bibs
            .filter((b) => (b.target.target_type === "couple")
                && !couples.bibs.map((hb) => hb.bib).includes(b.bib)
            )
    } as BibList;

    return (
        <>
            <h3>Couples</h3>
            <BibHeatListComponent bib_list={couples.bibs}
                heat_number={heat_number} missingBibList={missingBibList}
                id_phase={id_phase}
                defaultTarget={{ target_type: "couple" } as Target}
            />
        </>);
}


export function HeatsList({ id_phase, panel_data, heats, dataBibs }: { id_phase: number, panel_data: Panel, heats: HeatsArray, dataBibs: BibList }) {

    const sameTargetTypeDataBibs = { bibs: dataBibs.bibs.filter((b) => b.target.target_type === panel_data.panel_type) };

    const bibHeats: Target[] = heats?.heats ? (
        heats.heat_type === 'couple' ?
            heats.heats.flatMap((h) => h.couples)
            : (heats.heats as SinglesHeat[]).flatMap((h) => (
                h.leaders.concat(h.followers)
            ))
    ) : [];

    const missing_bibs = {
        bibs: sameTargetTypeDataBibs.bibs.filter(
            (bib) =>
                !bibHeats.some(
                    (t) => JSON.stringify(bib.target) === JSON.stringify(t) // deep compare targets
                )
        )
    };
    console.log("heat_type ", heats.heat_type, "heats", heats, "bibHeats", bibHeats, "missing_bibs", missing_bibs, "sameTargetTypeDataBibs", sameTargetTypeDataBibs);

    return (
        <>
            <p>
                <InitHeatsWithBibForm id_phase={id_phase} />
                <RandomizeHeatsForm id_phase={id_phase} />
            </p>

            {heats?.heats && heats?.heats.map((heat, index) => (
                // heat 0 réservée pour calculs internes
                // TODO : afficher warning si heat 0 non vide et Heat 1, ..., n non vides
                index === 0 ? <></> :
                    <>
                        <h1>Heat {index}</h1>
                        {heats.heat_type === "couple" &&
                            <CoupleHeatTable heat={heat as CouplesHeat}
                                dataBibs={sameTargetTypeDataBibs}
                                id_phase={id_phase}
                                heat_number={index}
                            />
                        }
                        {heats.heat_type === "single" &&
                            <SingleHeatTable heat={heat as SinglesHeat}
                                dataBibs={sameTargetTypeDataBibs}
                                id_phase={id_phase}
                                heat_number={index}
                            />
                        }
                    </>
            ))}

            <h1>New Heat {heats?.heats.length}</h1>
            {heats.heat_type === "couple" &&
                <CoupleHeatTable heat={{ couples: [] } as CouplesHeat}
                    dataBibs={sameTargetTypeDataBibs}
                    id_phase={id_phase}
                    heat_number={heats?.heats.length}
                />
            }
            {heats.heat_type === "single" &&
                <SingleHeatTable heat={{ leaders: [], followers: [] } as SinglesHeat}
                    dataBibs={sameTargetTypeDataBibs}
                    id_phase={id_phase}
                    heat_number={heats?.heats.length}
                />
            }

            <h3>Missing bibs</h3>
            <BareBibListComponent bib_list={missing_bibs.bibs} />
        </>
    );
}


export function HeatsListComponent({ id_phase, id_competition }: { id_phase: PhaseId, id_competition: CompetitionId }) {

    const { data: heats, isSuccess: isSuccessHeats } = useGetApiPhaseIdHeats(id_phase);

    const { data: dataBibs, isSuccess: isSuccessBibs } = useGetApiCompIdBibs(id_competition);

    const { data: panel_data, isSuccess: isSuccessPanel } = useGetApiPhaseIdJudges(id_phase);

    if (!isSuccessBibs) return <div>Chargement des bibs...</div>;
    if (!isSuccessHeats) return <div>Chargement des heats...</div>;
    if (!isSuccessPanel) return <div>Chargement de la phase...</div>;


    return (
        <>
            <HeatsList id_phase={id_phase} panel_data={panel_data} heats={heats} dataBibs={dataBibs} />
        </>
    );
}
