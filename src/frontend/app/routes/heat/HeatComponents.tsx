import React, { useEffect, useState, type JSX } from 'react';

import { useQueryClient } from "@tanstack/react-query";
import { Controller, useForm, type UseFormReturn } from "react-hook-form";

import {
    type Bib,
    type HeatTargetJudge, RoleItem,
} from "@hookgen/model";
import type { BibList, CouplesHeat, DancerId, HeatsArray, Phase, PhaseId, SinglesHeat, Target } from "@hookgen/model";
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
    error: string | undefined;
    success: string | undefined;
};



function BibHeatRowEditable({ formObject, missingBibList, onUpdate, onCancel, error, success }: HeatTargetRowEditableProps) {
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

    const defaultHeatTargetJudge = {
        ...heatTargetJudge,
        target: bib.target
    }

    const formObject = useForm<HeatTargetJudge>({
        defaultValues: defaultHeatTargetJudge,
    });

    const {
        handleSubmit,
        reset,
        setError,
    } = formObject;

    const queryClient = useQueryClient();

    const { mutate: addTargetToHeat, error, isError, isSuccess } = usePutApiPhaseIdHeatTarget({
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
                    queryKey: getGetApiPhaseIdHeatsQueryKey(id_phase),
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

    // useEffect(() => {
    //     reset(defaultHeatTargetJudge);
    // }, [, heatTargetJudge, bib, reset]);

    const errorMessage = isError ? error.message : undefined;
    const successMessage = isSuccess ? "Bib correctly added" : undefined;

    return (
        <tr key={`${defaultHeatTargetJudge.phase_id}-${defaultHeatTargetJudge.target.target_type}-${index}`}
            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>

            {isEditing ? (
                <BibHeatRowEditable
                    formObject={formObject}
                    missingBibList={missingBibList}
                    onUpdate={handleUpdate}
                    onCancel={handleCancel}
                    error={errorMessage}
                    success={successMessage}
                />
            ) : (
                <HeatTargetRowReadOnly
                    heatTarget={defaultHeatTargetJudge}
                    bib={bib}
                    onEdit={() => setIsEditing(true)}
                    onDelete={() => deleteTargetFromHeat({ id: defaultHeatTargetJudge.phase_id, data: defaultHeatTargetJudge })}
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
            setError("root.serverError", { message: "Cannot be default" });
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

    const get_bibs = (dancer_list: DancerId[]) => dataBibs?.bibs.filter(b => iter_target_dancers(b.target).map(dancer => dancer_list?.includes(dancer)).includes(true));
    const followers = get_bibs(heat.followers.flatMap(u => iter_target_dancers(u)));
    const leaders = get_bibs(heat.leaders.flatMap(u => iter_target_dancers(u)));
    const notInHeatFollowerBibs = {
        bibs: dataBibs.bibs
            .filter((b) => (b.target.target_type === "single" && b.target.role[0] === "Follower"
                && !followers.map((hb) => hb.bib).includes(b.bib)
            ))
    } as BibList;
    const notInHeatLeaderBibs = {
        bibs: dataBibs.bibs
            .filter((b) => (b.target.target_type === "single" && b.target.role[0] === "Leader"
                && !leaders.map((hb) => hb.bib).includes(b.bib)
            ))
    } as BibList;

    return (
        <>
            <div>
                <h3>Followers</h3>
                <BibHeatListComponent bib_list={followers}
                    heat_number={heat_number} missingBibList={notInHeatFollowerBibs}
                    id_phase={id_phase}
                    defaultTarget={{ target_type: "single", role: ["Follower"] } as Target}
                />
            </div>
            <div>
                <h3>Leaders</h3>
                <BibHeatListComponent bib_list={leaders}
                    heat_number={heat_number} missingBibList={notInHeatLeaderBibs}
                    id_phase={id_phase}
                    defaultTarget={{ target_type: "single", role: ["Leader"] } as Target}
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
    const couples = get_bibs(heat.couples.flatMap(u => iter_target_dancers(u)));
    const missingBibList = {
        bibs: dataBibs.bibs
            .filter((b) => (b.target.target_type === "couple")
                && (couples.filter((heat_couple) => b.bib === heat_couple.bib) ? false : true)
            )
    } as BibList;

    return (
        <>
            <h3>Couples</h3>
            <BibHeatListComponent bib_list={couples}
                heat_number={heat_number} missingBibList={missingBibList}
                id_phase={id_phase}
                defaultTarget={{ target_type: "couple" } as Target}
            />
        </>);
}


export function HeatsListComponent({ id_phase, phase, heats, dataBibs }: { id_phase: number, phase: Phase, heats: HeatsArray, dataBibs: BibList }) {

    const sameTargetTypeDataBibs = {bibs: dataBibs.bibs.filter((b) => b.target.target_type === )}
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
            <InitHeatsForm id_phase={id_phase} />


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