import React, { useState } from 'react';

import { useQueryClient } from "@tanstack/react-query";
import { Controller, useForm, type UseFormReturn } from "react-hook-form";

import {
    type Bib,
    type HeatTargetJudge, RoleItem,
} from "@hookgen/model";
import type { BibList, CompetitionId, CouplesHeat, HeatsArray, Panel, PhaseId, SinglesHeat, Target } from "@hookgen/model";
import {
    getGetApiPhaseIdCouplesHeatsQueryKey,
    getGetApiPhaseIdHeatsQueryKey, getGetApiPhaseIdSinglesHeatsQueryKey, useDeleteApiPhaseIdHeatTarget, useGetApiPhaseIdCouplesHeats, useGetApiPhaseIdHeats, useGetApiPhaseIdSinglesHeats, usePutApiPhaseIdConvertToCouple, usePutApiPhaseIdConvertToSingle, usePutApiPhaseIdHeatTarget
} from '~/hookgen/heat/heat';

import { dancerArrayFromTarget, DancerCell, get_bibs, } from '@routes/bib/BibComponents';
import { Field } from "@routes/index/field";

import { InitHeatsWithBibForm, RandomizeHeatsForm } from './InitHeatsForm';
import { useGetApiPhaseId } from '~/hookgen/phase/phase';
import { useGetApiCompIdBibs } from '~/hookgen/bib/bib';
import { useGetApiPhaseIdJudges } from '~/hookgen/judge/judge';

type HeatTargetRowReadOnlyProps = {
    bib_list: Bib[];
    onDelete: () => void
};


export function HeatTargetRowReadOnly({ bib_list, onDelete }: HeatTargetRowReadOnlyProps) {

    return (
        <>
            <td>
                {bib_list.map(b => (
                    <p key={b.bib}>{b.bib}</p>
                ))}
            </td>
            <td>
                {bib_list.map(b => (
                    <p key={b.bib}>
                        {b.target.target_type === "single" ?
                            b.target.role :
                            <> {RoleItem.Follower}
                                <br /> {RoleItem.Leader}
                            </>
                        }
                    </p>
                ))}
            </td>
            <td>
                {bib_list.map(b => (
                    <p key={b.bib}>
                        {dancerArrayFromTarget(b.target).map((i) => (
                            <DancerCell key={i} id_dancer={i} />
                        ))
                        }
                    </p>
                ))}
            </td>
            <td className="no-print">
                <button type="button" onClick={() => onDelete()}>
                    Delete
                </button>
            </td>
        </>

    );
}


function EditableHeatTarget({ heatTargetJudge, bibs }: { heatTargetJudge: HeatTargetJudge, bibs: BibList }) {

    const queryClient = useQueryClient();

    const { mutate: deleteTargetFromHeat } = useDeleteApiPhaseIdHeatTarget({
        mutation: {
            onSuccess: (id_phase) => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdHeatsQueryKey(id_phase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdCouplesHeatsQueryKey(id_phase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdSinglesHeatsQueryKey(id_phase),
                });
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
            }
        }
    });


    const bib_list = get_bibs(bibs, [heatTargetJudge.target])[0];
    console.log("found bib_list",bib_list, "heatTargetJudge.target", heatTargetJudge.target, "bibs", bibs);

    return (
        <HeatTargetRowReadOnly
            bib_list={bib_list}
            onDelete={() => deleteTargetFromHeat({ id: heatTargetJudge.phase_id, data: heatTargetJudge })}
        />
    );
}

type NewHeatTargetProps = {
    id_phase: PhaseId,
    defaultHeatTargetJudge: HeatTargetJudge,
    otherTargets: Target[],
    bibs: BibList
}
function NewHeatTarget({ id_phase, defaultHeatTargetJudge, otherTargets, bibs }: NewHeatTargetProps) {

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
            onSuccess: () => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdHeatsQueryKey(id_phase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdSinglesHeatsQueryKey(id_phase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdCouplesHeatsQueryKey(id_phase),
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

    const otherBibs = get_bibs(bibs, otherTargets);
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
                                            value: otherTargets[index]
                                        }
                                    };
                                    console.log("onChange Target", index, selected);
                                    field.onChange(selected);
                                }}
                            >
                                <option key={-1} value={-1}>----</option>
                                {otherBibs.map((bib_list, index) => (
                                    <option key={index} value={index}>
                                        {bib_list.map(b => dancerArrayFromTarget(b.target).map(id_dancer => (
                                            <>
                                                {b.bib}
                                                <DancerCell id_dancer={id_dancer} />
                                            </>
                                        )))}
                                    </option>)
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

type BibHeatListComponentProps = {
    targets: Target[],
    id_phase: PhaseId,
    heat_number: number,
    otherTargets: Target[],
    defaultTarget: Target
}
export function BibHeatListComponent({ targets, id_phase, heat_number, otherTargets, defaultTarget }: BibHeatListComponentProps) {


    const defaultHeatTarget = {
        phase_id: id_phase, heat_number: heat_number, target: defaultTarget,
        judge: -1,
        description: {
            artefact: "ranking",
            artefact_data: null,
        }
    } as HeatTargetJudge;

    const { data: phase, isSuccess: isSuccessPhase } = useGetApiPhaseId(id_phase);

    const { data: bibs, isSuccess: isSuccessBibs } = useGetApiCompIdBibs((phase?.competition ?? 0), { query: { enabled: isSuccessPhase } })

    if (!isSuccessPhase) return <tr>No phase found</tr>;
    if (!isSuccessBibs) return <tr>No bibs found</tr>;

    return (
        <>
            <table>
                <tbody>
                    <tr>
                        <th>Bib</th>
                        <th>Rôle</th>
                        <th>Target</th>
                        <th className="no-print">Action</th>
                    </tr>

                    {targets.map((target, index) => (

                        <tr key={`${defaultHeatTarget.phase_id}-${defaultHeatTarget.heat_number}-${target.target_type}-${dancerArrayFromTarget(target).join("-")}`}
                            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>

                            <EditableHeatTarget
                                bibs={bibs}
                                heatTargetJudge={{ ...defaultHeatTarget, target }} />
                        </tr>
                    ))}
                    <NewHeatTarget
                        id_phase={id_phase}
                        bibs={bibs}
                        defaultHeatTargetJudge={defaultHeatTarget}
                        otherTargets={otherTargets} />
                </tbody>
            </table>
        </>
    );
}


type SingleHeatProps = {
    heat: SinglesHeat,
    heat_number: number,
    phaseTargets: Target[],
    otherTargets: Target[],
    id_phase: number,
}

export function SingleHeatTable({ heat, phaseTargets, otherTargets, heat_number, id_phase }: SingleHeatProps) {


    const otherFollowers = phaseTargets.filter(t =>
        (!heat.followers.find(tt => JSON.stringify(t) === JSON.stringify(tt))) && t.target_type === "single" && t.role[0] === "Follower"
    ).concat(otherTargets.filter(t => t.target_type === "couple" || t.role[0] === "Follower"));

    const otherLeaders = phaseTargets.filter(t =>
        (!heat.leaders.find(tt => JSON.stringify(t) === JSON.stringify(tt))) && t.target_type === "single" && t.role[0] === "Leader"
    ).concat(otherTargets.filter(t => t.target_type === "couple" || t.role[0] === "Leader"));


    return (
        <div className='bib-table-container'>
            <div className='bib-table-column'>
                <h3>Followers</h3>
                <BibHeatListComponent targets={heat.followers}
                    heat_number={heat_number} otherTargets={otherFollowers}
                    id_phase={id_phase}
                    defaultTarget={{ target_type: "single", role: ["Follower"] } as Target}
                />
            </div>
            <div className='bib-table-column'>
                <h3>Leaders</h3>
                <BibHeatListComponent targets={heat.leaders}
                    heat_number={heat_number} otherTargets={otherLeaders}
                    id_phase={id_phase}
                    defaultTarget={{ target_type: "single", role: ["Leader"] } as Target}
                />
            </div>
        </div>);
}

type CoupleHeatTableProps = {
    heat: CouplesHeat,
    phaseTargets: Target[],
    otherTargets: Target[],
    heat_number: number,
    id_phase: number,
}

export function CoupleHeatTable({ heat, phaseTargets, otherTargets, heat_number, id_phase }: CoupleHeatTableProps) {

    const ot = phaseTargets.filter(t =>
        !heat.couples.find(tt => JSON.stringify(t) === JSON.stringify(tt))
    ).concat(otherTargets);

    return (
        <div className=''>
            <div className=''>
                <h3>Couples</h3>
                <BibHeatListComponent targets={heat.couples}
                    heat_number={heat_number} otherTargets={ot}
                    id_phase={id_phase}
                    defaultTarget={{ target_type: "couple" } as Target}
                />
            </div>
        </div>
    );
}


export function concatHeatsTargets(heats: HeatsArray) {

    if (!heats.heats) return [];
    if (heats.heat_type === 'couple') return heats.heats.flatMap((h) => h.couples);

    return heats.heat_type === "single" ? heats.heats.flatMap((h) => (
        h.leaders.concat(h.followers)
    )) : [];
}

export function HeatsList({ id_phase, panel_data, heats }: { id_phase: number, panel_data: Panel, heats: HeatsArray }) {

    const { data: singlesHeats, isSuccess: isSuccessSinglesHeats } = useGetApiPhaseIdSinglesHeats(id_phase);
    const { data: couplesHeats, isSuccess: isSuccessCouplesHeats } = useGetApiPhaseIdCouplesHeats(id_phase);

    if (!isSuccessSinglesHeats) return <>Chargement des poules</>;
    if (!isSuccessCouplesHeats) return <>Chargement des poules</>;

    const dataHeats: Target[] = concatHeatsTargets(singlesHeats).concat(concatHeatsTargets(couplesHeats));
    const filteredHeats = { heats: heats.heats.slice(1), heat_type: heats.heat_type } as HeatsArray;
    const currentHeats = concatHeatsTargets(filteredHeats);

    const missingHeatsTargets = dataHeats.filter(t => (
        !currentHeats.find(tt => JSON.stringify(t) === JSON.stringify(tt))
    ));

    //console.log("missingHeatsTargets", missingHeatsTargets, "currentHeats", currentHeats, "heats", heats, "filteredHeats", filteredHeats);

    return (
        <>
            <p className='no-print'>
                <InitHeatsWithBibForm id_phase={id_phase} />
                <RandomizeHeatsForm id_phase={id_phase} />
            </p>

            {heats?.heats && heats?.heats.map((heat, index) => (
                // heat 0 réservée pour calculs internes
                // TODO : afficher warning si heat 0 non vide et Heat 1, ..., n non vides
                index === -1 ? <></> :
                    <>
                        <div className={index === 0 ? 'no-print' : ''} key={index}>
                            <h1>Heat {index}</h1>
                            {panel_data.panel_type === "couple" && heats.heat_type === "couple" &&
                                <CoupleHeatTable heat={heat as CouplesHeat}
                                    phaseTargets={currentHeats}
                                    otherTargets={missingHeatsTargets}
                                    id_phase={id_phase}
                                    heat_number={index}
                                />
                            }
                            {panel_data.panel_type === "single" && heats.heat_type === "single" &&
                                <SingleHeatTable heat={heat as SinglesHeat}
                                    phaseTargets={currentHeats}
                                    otherTargets={missingHeatsTargets}
                                    id_phase={id_phase}
                                    heat_number={index}
                                />
                            }
                        </div>
                    </>
            ))}

            <div className='no-print'>
                <h1>New Heat {heats?.heats.length}</h1>
                {panel_data.panel_type === "couple" && heats.heat_type === "couple" &&
                    <CoupleHeatTable heat={{ couples: [] } as CouplesHeat}
                        phaseTargets={currentHeats}
                        otherTargets={missingHeatsTargets}
                        id_phase={id_phase}
                        heat_number={heats?.heats.length}
                    />
                }
                {panel_data.panel_type === "single" && heats.heat_type === "single" &&
                    <SingleHeatTable heat={{ leaders: [], followers: [] } as SinglesHeat}
                        phaseTargets={currentHeats}
                        otherTargets={missingHeatsTargets}
                        id_phase={id_phase}
                        heat_number={heats?.heats.length}
                    />
                }

                <h3>Missing targets</h3>
                <BibHeatListComponent
                    id_phase={id_phase}
                    heat_number={0}
                    targets={missingHeatsTargets}
                    otherTargets={[]}
                    defaultTarget={{ target_type: panel_data.panel_type } as Target}
                />
            </div>
        </>
    );
}


export function HeatsListComponent({ id_phase, id_competition }: { id_phase: PhaseId, id_competition: CompetitionId }) {

    const { data: heats, isSuccess: isSuccessHeats } = useGetApiPhaseIdHeats(id_phase);

    const { data: panel_data, isSuccess: isSuccessPanel } = useGetApiPhaseIdJudges(id_phase);

    if (!isSuccessHeats) return <div>Chargement des heats...</div>;
    if (!isSuccessPanel) return <div>Chargement de la phase...</div>;


    return (
        <>
            <HeatsList id_phase={id_phase} panel_data={panel_data} heats={heats} />
        </>
    );
}
