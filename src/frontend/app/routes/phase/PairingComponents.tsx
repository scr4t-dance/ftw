import React, { useEffect, useState } from 'react';

import { useQueryClient } from "@tanstack/react-query";
import { useForm, type SubmitHandler } from "react-hook-form";
import cx from "classnames";

import {
    RoleItem,
    type HeatTargetJudge,
} from "@hookgen/model";
import type { Bib, BibList, CompetitionId, CoupleTarget, DancerId, DancerIdList, HeatCoupleTargetList, HeatsArray, Panel, PhaseId, SinglesHeat, SingleTarget, Target } from "@hookgen/model";
import {
    getGetApiPhaseIdCouplesHeatsQueryKey,
    getGetApiPhaseIdHeatsQueryKey, getGetApiPhaseIdSinglesHeatsQueryKey, useDeleteApiPhaseIdHeatTarget, useGetApiPhaseIdCouplesHeats, useGetApiPhaseIdSinglesHeats, usePutApiPhaseIdConvertToCouple, usePutApiPhaseIdConvertToSingle, usePutApiPhaseIdHeatTarget,
    usePutApiPhaseIdMixCouples
} from '~/hookgen/heat/heat';

import { dancerArrayFromTarget, DancerCell, get_bibs, } from '@routes/bib/BibComponents';
import { Field } from "@routes/index/field";
import { InitHeatsWithBibForm } from '@routes/heat/InitHeatsForm';
import { useGetApiPhaseId } from '~/hookgen/phase/phase';
import { useGetApiCompIdBibs } from '~/hookgen/bib/bib';
import { HeatTargetRowReadOnly } from '@routes/heat/HeatComponents';
import { get_follower_from_bib, get_leader_from_bib, SelectCoupleTargetForm, SelectSingleTargetForm, type BibCoupleTargetForm, type BibSingleTargetForm } from '../bib/NewBibFormComponent';
import { Link } from 'react-router';



function PairingRow({ target, id_phase, heat_number, bibs }: { target: Target, id_phase: PhaseId, heat_number: number, bibs: BibList }) {

    const queryClient = useQueryClient();

    const { mutate: deleteTargetFromHeat } = useDeleteApiPhaseIdHeatTarget({
        mutation: {
            onSuccess: (id_phase) => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdHeatsQueryKey(id_phase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdSinglesHeatsQueryKey(id_phase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdCouplesHeatsQueryKey(id_phase),
                });
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
            }
        }
    });

    const htj = {
        phase_id: id_phase,
        heat_number: heat_number,
        target,
        judge: 0,
        description: { artefact: "ranking", artefact_data: null }
    } satisfies HeatTargetJudge

    const bib_list = get_bibs(bibs, [target])[0];

    return (
        <>
            <HeatTargetRowReadOnly
                bib_list={bib_list}
                onDelete={() => deleteTargetFromHeat({ id: id_phase, data: htj })}
            />
        </>

    );
}

type CombineCoupleFormProps = {
    targets: Target[],
    id_phase: PhaseId,
    heat_number: number,
}
export function CombineCoupleForm({ targets, id_phase, heat_number }: CombineCoupleFormProps) {

    const followers: Array<SingleTarget> = targets
        .filter(t => t.target_type === "couple" || t.role[0] === "Follower")
        .map((t) => t.target_type === "couple" ? t.follower : t.target)
        .map(id_dancer => ({ target_type: "single", target: id_dancer, role: ["Follower"] }));
    const leaders: Array<SingleTarget> = targets
        .filter(t => t.target_type === "couple" || t.role[0] === "Leader")
        .map((t) => t.target_type === "couple" ? t.leader : t.target)
        .map(id_dancer => ({ target_type: "single", target: id_dancer, role: ["Leader"] }));

    const {
        register,
        handleSubmit,
        setError,
        formState: { errors },
    } = useForm<Array<DancerId>>({
        defaultValues: followers.map(t => t.target)
    });

    const { data: phase, isSuccess: isSuccessPhase } = useGetApiPhaseId(id_phase);
    const { data: bibs, isSuccess: isSuccessBibs } = useGetApiCompIdBibs((phase?.competition ?? 0), { query: { enabled: isSuccessPhase } })

    const queryClient = useQueryClient();
    const { mutate: submitNewCouples } = usePutApiPhaseIdMixCouples({
        mutation: {
            onSuccess: (id_phase) => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdHeatsQueryKey(id_phase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdSinglesHeatsQueryKey(id_phase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdCouplesHeatsQueryKey(id_phase),
                });
            },
            onError: (err) => {
                setError("root.serverError", err);
                console.error('Error updating competition:', err);
            }
        }
    })

    if (!isSuccessPhase) return <tr>No phase found</tr>;
    if (!isSuccessBibs) return <tr>No bibs found</tr>;

    const followerBibs = get_bibs(bibs, followers);

    console.log("followerBibs", followerBibs, "bibs", bibs);

    function onSubmit(data: DancerId[]) {
        const targets = leaders.map((t, index) => ({
            target_type: "couple",
            leader: t.target,
            follower: Number(data[index]) as DancerId,
        } satisfies CoupleTarget));

        const couple_list: HeatCoupleTargetList = { couples: targets, heat_number: heat_number }
        submitNewCouples({ id: id_phase, data: couple_list });
    }

    return (
        <form onSubmit={handleSubmit(onSubmit)}>
            <button type='submit'>
                Enregistrer les nouveaux couples
            </button>
            {errors.root?.formValidation &&
                <div className="error_message">⚠️ {errors.root.formValidation.message}</div>
            }
            {errors.root?.serverError &&
                <div className="error_message">⚠️ {errors.root.serverError.message}</div>
            }
            <table>
                <tbody>
                    <tr>
                        <th>Leader</th>
                        <th>Follower actuel</th>
                        <th>Nouveau Follower</th>
                    </tr>

                    {targets.map((target, index) => (

                        <tr key={`${id_phase}-${heat_number}-${target.target_type}-${dancerArrayFromTarget(target).join("-")}`}
                            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
                            <td>
                                {target.target_type === "couple" &&
                                    <DancerCell id_dancer={target.leader} />
                                }
                            </td>
                            <td>
                                {target.target_type === "couple" &&
                                    <DancerCell id_dancer={target.follower} />
                                }
                            </td>
                            <td>
                                <Field>
                                    <select {...register(`${index}`, { valueAsNumber: true })}>
                                        {followers.map((follower_target, follower_index) => (
                                            <>
                                                <option value={follower_target.target}>
                                                    {[followerBibs[follower_index].map(b => b.bib).join(","), " "]}
                                                    <DancerCell id_dancer={follower_target.target} />
                                                    {[" ", follower_target.target]}
                                                </option>
                                            </>
                                        ))}

                                    </select>
                                </Field>
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>

            <button type='submit'>
                Enregistrer les nouveaux couples
            </button>
            {errors.root?.formValidation &&
                <div className="error_message">⚠️ {errors.root.formValidation.message}</div>
            }
            {errors.root?.serverError &&
                <div className="error_message">⚠️ {errors.root.serverError.message}</div>
            }
        </form>
    );
}


type BibHeatListComponentProps = {
    targets: Target[],
    id_phase: PhaseId,
    heat_number: number,
}
export function PairingTable({ targets, id_phase, heat_number }: BibHeatListComponentProps) {

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
                        <th>Action</th>
                    </tr>

                    {targets.map((target, index) => (

                        <tr key={`${id_phase}-${heat_number}-${target.target_type}-${dancerArrayFromTarget(target).join("-")}`}
                            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>

                            <PairingRow
                                bibs={bibs}
                                target={target}
                                id_phase={id_phase}
                                heat_number={heat_number}
                            />
                        </tr>
                    ))}
                </tbody>
            </table>
        </>
    );
}


type PairingHeatTableProps = {
    targetArray: Target[],
    heat_number: number,
    id_phase: number,
}

export function PairingHeatTable({ targetArray: targetArray, heat_number, id_phase }: PairingHeatTableProps) {

    const [isMixing, toggleMixingForm] = useState(false);

    const queryClient = useQueryClient();

    const { mutate: convertToSingle } = usePutApiPhaseIdConvertToSingle({
        mutation: {
            onSuccess: (id_phase) => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdHeatsQueryKey(id_phase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdSinglesHeatsQueryKey(id_phase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdCouplesHeatsQueryKey(id_phase),
                });
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
            }
        }
    });
    const { mutate: convertToCouple } = usePutApiPhaseIdConvertToCouple({
        mutation: {
            onSuccess: (id_phase) => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdHeatsQueryKey(id_phase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdSinglesHeatsQueryKey(id_phase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdCouplesHeatsQueryKey(id_phase),
                });
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
            }
        }
    });

    return (
        <>
            <button type="button" className='btn colored_btn'
                onClick={() => convertToSingle({ id: id_phase, data: { heat_number: heat_number } })}>
                Convertir en poules de compétiteurices solo
            </button>
            <button type="button" className='btn colored_btn'
                onClick={() => convertToCouple({ id: id_phase, data: { heat_number: heat_number } })}>
                Convertir en poules de coupétiteurices duo
            </button>
            <button type="button" className={cx("btn", isMixing ? "colored_btn" : "")}
                onClick={() => toggleMixingForm(!isMixing)}>
                Modifier les couples
            </button>
            {isMixing &&
                <CombineCoupleForm targets={targetArray}
                    heat_number={heat_number}
                    id_phase={id_phase}
                />
            }
            {!isMixing &&
                <PairingTable targets={targetArray}
                    heat_number={heat_number}
                    id_phase={id_phase}
                />
            }
        </>);
}


export function AddAnyBibToPhase({ id_phase, heat_number }: { id_phase: PhaseId, heat_number: number }) {

    const url = "/admin/dancers/"

    const default_single_target: SingleTarget = { target_type: "single", target: 1, role: [RoleItem.Follower] };
    const default_couple_target: CoupleTarget = { target_type: "couple", follower: 1, leader: 2 };

    const defaultHeatTarget = {
        phase_id: id_phase, heat_number: heat_number, target: default_single_target,
        judge: -1,
        description: {
            artefact: "ranking",
            artefact_data: null,
        }
    } as HeatTargetJudge;

    const formObject = useForm<Bib>({
        defaultValues: {
            competition: 0,
            bib: 100,
            target: default_single_target,
        }
    });

    const {
        register,
        handleSubmit,
        watch,
        reset,
        setError,
        formState: { errors },
    } = formObject;

    const queryClient = useQueryClient();

    const { mutate: addTargetToHeat, isSuccess } = usePutApiPhaseIdHeatTarget({
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

    const { data: phaseData, isSuccess: isSuccessPhase } = useGetApiPhaseId(id_phase);

    const { data: bibs_list, isSuccess: isSuccessBibs } = useGetApiCompIdBibs(
        phaseData?.competition as CompetitionId, {
        query: {
            enabled: isSuccessPhase
        }
    }
    );

    const targetType = watch("target.target_type");

    const onSubmit: SubmitHandler<Bib> = (data) => {

        const htj = {
            ...defaultHeatTarget,
            target: data.target
        }

        addTargetToHeat({ id: id_phase, data: htj });
    };

    useEffect(() => {
        // Reset the entire 'target' field when 'target.target_type' changes
        reset((prevValues: Bib) => ({
            ...prevValues,
            target: (targetType === "single" ? default_single_target : default_couple_target)
        }));
    }, [targetType, reset]);

    if (!isSuccessPhase) return null;
    if (!isSuccessBibs) return <div>Chargement des bibs...</div>;

    const follower_select_bibs_list = bibs_list.bibs.map(
        (bib) => get_follower_from_bib(bib, (b) => String(b.bib))
    ).filter((v) => v != null);
    const leader_select_bibs_list = bibs_list.bibs.map(
        (bib) => get_leader_from_bib(bib, (b) => String(b.bib))
    ).filter((v) => v != null);

    return (
        <>
            <form onSubmit={handleSubmit(onSubmit)} >
                {isSuccess &&
                    <div className="success_message">
                        <p>
                            ✅ Nouvelle Target ajoutée avec succès.
                        </p>
                    </div>
                }

                <input type="hidden" {...register("competition")} />

                <input type="hidden" {...register("bib")} />


                <Field label="Target type" error={errors.target?.target_type?.message}>
                    <select {...register("target.target_type")}>
                        <option value="single">Single</option>
                        <option value="couple">Couple</option>
                    </select>
                </Field>

                {targetType === "single" && (
                    <SelectSingleTargetForm
                        formObject={formObject as BibSingleTargetForm}
                        follower_id_list={follower_select_bibs_list}
                        leader_id_list={leader_select_bibs_list} />
                )}

                {targetType === "couple" && (
                    <SelectCoupleTargetForm
                        formObject={formObject as BibCoupleTargetForm}
                        follower_id_list={follower_select_bibs_list}
                        leader_id_list={leader_select_bibs_list} />
                )}

                {errors.root?.formValidation &&
                    <div className="error_message">⚠️ {errors.root.formValidation.message}</div>
                }

                {errors.root?.serverError &&
                    <div className="error_message">⚠️ {errors.root.serverError.message}</div>
                }
                <button type="submit" >Ajouter un-e nouvelle compétiteurice à la poule 0</button>

            </form >
        </>
    );
}



export function PairingListComponent({ id_phase }: { id_phase: number, panel_data: Panel, heats: HeatsArray, dataBibs: BibList }) {

    const { data: singlesHeats, isSuccess: isSuccessSinglesHeats } = useGetApiPhaseIdSinglesHeats(id_phase);
    const { data: couplesHeats, isSuccess: isSuccessCouplesHeats } = useGetApiPhaseIdCouplesHeats(id_phase);

    if (!isSuccessSinglesHeats) return <>Chargement des poules</>;
    if (!isSuccessCouplesHeats) return <>Chargement des poules</>;

    const combinedHeats = couplesHeats.heats.map((h, index) =>
        (h.couples as Target[])
            .concat(singlesHeats.heats[index].leaders)
            .concat(singlesHeats.heats[index].followers)
    );

    return (
        <>
            <div className='no-print'>
                <InitHeatsWithBibForm id_phase={id_phase} />
                <AddAnyBibToPhase id_phase={id_phase} heat_number={0} />
            </div>

            {combinedHeats.map((targetArray, index) => (
                <div key={index}>
                    <h1>Heat {index}</h1>
                    <PairingHeatTable targetArray={targetArray}
                        id_phase={id_phase}
                        heat_number={index}
                    />
                </div>
            ))}
        </>
    );
}
