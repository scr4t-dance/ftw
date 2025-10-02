import React, { useEffect, useState } from 'react';

import { useQueryClient } from "@tanstack/react-query";
import { Controller, useForm, type UseFormReturn } from "react-hook-form";

import {
    type Bib,
    type HeatTargetJudge, RoleItem,
} from "@hookgen/model";
import type { BibList, CouplesHeat, DancerId, HeatsArray, PhaseId, SinglesHeat, Target } from "@hookgen/model";
import {
    getGetApiCompIdBibsQueryKey,
} from "@hookgen/bib/bib";
import {
    getGetApiPhaseIdHeatsQueryKey, useDeleteApiPhaseIdHeatTarget, usePutApiPhaseIdHeatTarget
} from '~/hookgen/heat/heat';

import { BareBibListComponent, dancerArrayFromTarget, DancerCell, } from '@routes/bib/BibComponents';
import { Field } from "@routes/index/field";
import { InitHeatsForm } from './InitHeatsForm';


type HeatTargetRowReadOnlyProps = {
    heatTarget: HeatTargetJudge;
    bib: Bib;
    onEdit: () => void;
    onDelete: () => void
};

function HeatTargetRowReadOnly({ heatTarget, bib, onEdit, onDelete }: HeatTargetRowReadOnlyProps) {

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
                <button type="button" onClick={() => onEdit()}>
                    Switch
                </button>
                <button type="button" onClick={() => onDelete()}>
                    Delete
                </button>
            </td>
        </>

    );
}


type HeatTargetRowEditableProps = {
    formObject: UseFormReturn<HeatTargetJudge, any, HeatTargetJudge>;
    missingBibList: BibList;
    onUpdate: () => void;
    onCancel: () => void;
};



function BibHeatRowEditable({ formObject, missingBibList, onUpdate, onCancel }: HeatTargetRowEditableProps) {
    const {
        control,
        formState: { errors, defaultValues },
        watch
    } = formObject;

    const targetType = watch("target.target_type");

    return (
        <>
            <td>
                {targetType}
            </td>

            <td>
                <Field label="" error={errors.target?.message}>
                    <Controller
                        control={control}
                        name={"target"}
                        render={({ field }) => (
                            <select
                                onChange={(e) => {
                                    const index = Number(e.target.value);
                                    const selected = {
                                        ...e,
                                        target: {
                                            ...e.target,
                                            value: {
                                                ...defaultValues,
                                                target: missingBibList.bibs[index].target
                                            }
                                        }
                                    };
                                    field.onChange(selected);
                                }}
                            >
                                {[{ bib: 0, target: defaultValues?.target } as Bib].concat(missingBibList.bibs).map((bib, index) => (
                                    <option key={index} value={index}>{bib.bib}</option>)
                                )}
                            </select>
                        )}
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
                    <td><DancerCell id_dancer={formObject.getValues("target.follower")} /></td>
                    <td><DancerCell id_dancer={formObject.getValues("target.leader")} /></td>
                </>
            )}
            <td>
                <button type="button" onClick={() => onUpdate()}>Màj</button>
                <button type="button" onClick={() => onCancel()} >Annuler</button>
            </td>
        </>
    );
}

function EditableHeatTarget({ heatTargetJudge, bib, index, missingBibList }: { heatTargetJudge: HeatTargetJudge, bib: Bib, index: number, missingBibList: BibList }) {


    const [isEditing, setIsEditing] = useState(false);

    const formObject = useForm<HeatTargetJudge>({
        defaultValues: heatTargetJudge
    });

    const {
        handleSubmit,
        reset,
        setError,
    } = formObject;

    const queryClient = useQueryClient();

    const { mutate: addTargetToHeat } = usePutApiPhaseIdHeatTarget({
        mutation: {
            onSuccess: (id_phase) => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdHeatsQueryKey(id_phase),
                });
                setIsEditing(false);
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
                setError("root.serverError", { message: 'Erreur lors de l’ajout de la compétition.' });
            }
        }
    });

    const { mutate: deleteTargetFromHeat } = useDeleteApiPhaseIdHeatTarget({
        mutation: {
            onSuccess: (id_phase) => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiCompIdBibsQueryKey(id_phase),
                });
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
                setError("root.serverError", { message: err.message });
            }
        }
    });

    const handleUpdate = handleSubmit((data) => {
        addTargetToHeat({ id: data.phase_id, data });
    });

    const handleCancel = () => {
        reset();
        setIsEditing(false);
    };

    useEffect(() => {
        reset(heatTargetJudge);
    }, [heatTargetJudge, reset]);

    return (
        <tr key={`${heatTargetJudge.phase_id}-${heatTargetJudge.target}`}
            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>

            {isEditing ? (
                <BibHeatRowEditable
                    formObject={formObject}
                    missingBibList={missingBibList}
                    onUpdate={handleUpdate}
                    onCancel={handleCancel}
                />
            ) : (
                <HeatTargetRowReadOnly
                    heatTarget={heatTargetJudge}
                    bib={bib}
                    onEdit={() => setIsEditing(true)}
                    onDelete={() => deleteTargetFromHeat({ id: heatTargetJudge.phase_id, data: heatTargetJudge })}
                />
            )
            }
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
        formState: { errors, defaultValues }
    } = formObject;

    const queryClient = useQueryClient();

    const { mutate: addTargetToHeat } = usePutApiPhaseIdHeatTarget({
        mutation: {
            onSuccess: (id_phase) => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdHeatsQueryKey(id_phase),
                });
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
                setError("root.serverError", { message: 'Erreur lors de l’ajout de la compétition.' });
            }
        }
    });

    const handleUpdate = handleSubmit((data) => {
        addTargetToHeat({ id: data.phase_id, data });
    });

    const targetType = watch("target.target_type");

    return (
        <tr>
            <td>
                {targetType}
            </td>

            <td>
                <Field label="" error={errors.target?.message}>
                    <Controller
                        control={control}
                        name={"target"}
                        render={({ field }) => (
                            <select
                                onChange={(e) => {
                                    const index = Number(e.target.value);
                                    const selected = {
                                        ...e,
                                        target: {
                                            ...e.target,
                                            value: {
                                                ...defaultValues,
                                                target: missingBibList.bibs[index].target
                                            }
                                        }
                                    };
                                    field.onChange(selected);
                                }}
                            >
                                {[{ bib: 0, target: defaultValues?.target } as Bib].concat(missingBibList.bibs).map((bib, index) => (
                                    <option key={index} value={index}>{bib.bib}</option>)
                                )}
                            </select>
                        )}
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
                    <td><DancerCell id_dancer={formObject.getValues("target.follower")} /></td>
                    <td><DancerCell id_dancer={formObject.getValues("target.leader")} /></td>
                </>
            )}
            <td>
                <button type="submit" onClick={() => handleUpdate()}>Add new</button>
            </td>
        </tr>
    );
}

export function BibHeatListComponent({ bib_list, id_phase, heat_number, missingBibList }: { bib_list: Bib[], id_phase: PhaseId, heat_number: number, missingBibList: BibList }) {

    const defaultHeatTarget = {
        phase_id: id_phase, heat_number: heat_number, target: { target_type: "single" } as Target,
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
                            missingBibList={missingBibList}
                            bib={bibObject}
                            index={index} />
                    ))}
                    <NewHeatTarget defaultHeatTargetJudge={defaultHeatTarget} missingBibList={missingBibList} />
                </tbody>
            </table>
        </>
    );
}


const iter_target_dancers = (t: Target) => t.target_type === "single"
    ? [t.target]
    : [t.follower, t.leader];

type SingleHeatProps = {
    heat: SinglesHeat, dataBibs: BibList,
    missing_bibs: BibList,
    heat_number: number,
    id_phase: number,
}

export function SingleHeatTable({ heat, dataBibs, missing_bibs, heat_number, id_phase }: SingleHeatProps) {


    const followers: DancerId[] = heat.followers.flatMap(u => iter_target_dancers(u));
    const leaders: DancerId[] = heat.leaders.flatMap(u => iter_target_dancers(u));
    const get_bibs = (dancer_list: DancerId[]) => dataBibs?.bibs.filter(b => iter_target_dancers(b.target).map(dancer => dancer_list?.includes(dancer)).includes(true));

    return (
        <>
            <div>
                <h3>Followers</h3>
                <BibHeatListComponent bib_list={get_bibs(followers)}
                    heat_number={heat_number} missingBibList={missing_bibs}
                    id_phase={id_phase}
                />
            </div>
            <div>
                <h3>Leaders</h3>
                <BibHeatListComponent bib_list={get_bibs(leaders)}
                    heat_number={heat_number} missingBibList={missing_bibs}
                    id_phase={id_phase}
                />
            </div>
        </>);
}

type CoupleHeatTableProps = {
    heat: CouplesHeat, dataBibs: BibList,
    missing_bibs: BibList,
    heat_number: number,
    id_phase: number,
}

export function CoupleHeatTable({ heat, dataBibs, missing_bibs, heat_number, id_phase }: CoupleHeatTableProps) {


    const get_bibs = (dancer_list: DancerId[]) => dataBibs?.bibs.filter(b => iter_target_dancers(b.target).map(dancer => dancer_list?.includes(dancer)).includes(true));

    return (
        <>
            <h3>Couples</h3>
            <BibHeatListComponent bib_list={get_bibs(heat.couples.flatMap(u => iter_target_dancers(u)))}
                heat_number={heat_number} missingBibList={missing_bibs}
                id_phase={id_phase}
            />
        </>);
}


export function HeatsListComponent({ id_phase, heats, dataBibs }: { id_phase: number, heats: HeatsArray, dataBibs: BibList }) {

    const bibHeats: Target[] = heats?.heats ? (
        heats.heat_type === 'couple' ?
            heats.heats.flatMap((h) => h.couples)
            : (heats.heats as SinglesHeat[]).flatMap((h) => (
                h.leaders.concat(h.followers)
            ))
    ) : [];
    const missing_bibs_array = dataBibs.bibs.filter(
        (bib) =>
            !bibHeats.some(
                (t) => JSON.stringify(bib.target) === JSON.stringify(t) // deep compare targets
            )
    );
    const missing_bibs = { bibs: missing_bibs_array };
    console.log("heat_type ", heats.heat_type, "bibHeats", bibHeats, "missing_bibs", missing_bibs, "dataBibs", dataBibs);

    return (
        <>
            <p>
                <InitHeatsForm id_phase={id_phase} />

            </p>

            {heats?.heats && heats?.heats.map((heat, index) => (
                <>
                    <h1>Heat {index}</h1>
                    {heats.heat_type === "couple" &&
                        <CoupleHeatTable heat={heat as CouplesHeat}
                            dataBibs={dataBibs} missing_bibs={missing_bibs}
                            id_phase={id_phase}
                            heat_number={index}
                        />
                    }
                    {heats.heat_type === "single" &&
                        <SingleHeatTable heat={heat as SinglesHeat}
                            dataBibs={dataBibs} missing_bibs={missing_bibs}
                            id_phase={id_phase}
                            heat_number={index}
                        />
                    }
                </>
            ))}

            <h1>New Heat {heats?.heats.length}</h1>
            {heats.heat_type === "couple" &&
                <CoupleHeatTable heat={{ couples: [] } as CouplesHeat}
                    dataBibs={dataBibs} missing_bibs={missing_bibs}
                    id_phase={id_phase}
                    heat_number={heats?.heats.length}
                />
            }
            {heats.heat_type === "single" &&
                <SingleHeatTable heat={{ leaders: [], followers: [] } as SinglesHeat}
                    dataBibs={dataBibs} missing_bibs={missing_bibs}
                    id_phase={id_phase}
                    heat_number={heats?.heats.length}
                />
            }

            <h3>Missing bibs</h3>
            <BareBibListComponent bib_list={missing_bibs.bibs} />
        </>
    );
}