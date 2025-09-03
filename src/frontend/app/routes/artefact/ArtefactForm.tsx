import React, { useEffect } from 'react';

import type { Bib, CompetitionId, DancerId, DancerIdList, HeatTargetJudgeArtefactArray, Phase, PhaseId, Target } from "@hookgen/model";
import { Yan } from "@hookgen/model";
import { useParams } from "react-router";
import { useGetApiPhaseId } from "@hookgen/phase/phase";
import { useGetApiPhaseIdSinglesHeats } from "~/hookgen/heat/heat";
import { useQueryClient } from "@tanstack/react-query";
import { useGetApiCompIdBibs } from '~/hookgen/bib/bib';
import { getGetApiPhaseIdArtefactJudgeIdJudgeQueryKey, useGetApiPhaseIdArtefactJudgeIdJudge, usePutApiPhaseIdArtefactJudgeIdJudge, } from '~/hookgen/artefact/artefact';
import { FormProvider, get, useFieldArray, useForm, type SubmitHandler } from 'react-hook-form';
import { Field } from '@routes/index/field';
import { DancerCell } from '@routes/bib/BibList';

const judges: DancerIdList = { dancers: [1] };
const head_judge: DancerId = 1;

export const yan_values: (string | undefined)[] = Object.values(Yan);

const iter_target_dancers = (t: Target) => t.target_type === "single"
    ? [t.target]
    : [t.follower, t.leader];


export function ArtefactFormComponent({ phase_id, phase, heat_number, judge_id, bib_list }: { phase_id: PhaseId, phase: Phase, heat_number: number, judge_id: DancerId, bib_list: Array<Bib> }) {


    const all_judges: DancerId[] = judges.dancers.concat([head_judge]);


    const { data: artefactData, isSuccess, isLoading, isError: isDetailsError } = useGetApiPhaseIdArtefactJudgeIdJudge(phase_id, judge_id);

    const queryClient = useQueryClient();

    const { mutate: mutateArtefacts } = usePutApiPhaseIdArtefactJudgeIdJudge({
        mutation: {
            onSuccess: () => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdArtefactJudgeIdJudgeQueryKey(phase_id, judge_id),
                });
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
                setError("root.serverError", { message: 'Erreur lors de l’ajout de la compétition.' });
            }
        }
    });

    const formObject = useForm<HeatTargetJudgeArtefactArray>({
        disabled: isLoading,
        defaultValues: artefactData
    });

    const {
        control,
        register,
        reset,
        handleSubmit,
        setError,
        setValue,
        formState: { errors } } = formObject;

    const { fields } = useFieldArray({
        control,
        name: "artefacts",
    });

    useEffect(() => {
        if (isSuccess && artefactData) {
            console.log("reloading Artefact form")
            reset(artefactData);
        }
    }, [isSuccess, artefactData, reset]);

    useEffect(() => {
        fields.forEach((_, idx) => {
            setValue(`artefacts.${idx}.artefact.artefact_type`, phase.judge_artefact_descr.artefact);
        });
    }, [fields, setValue, phase.judge_artefact_descr.artefact]);


    if (!isSuccess) return <div>Loading artefacts...</div>;
    if (isDetailsError) return (
        <div>
            Error loading artefact data
            {errors?.artefacts?.message}
        </div>);
    if (!bib_list || bib_list.length === 0) {
        return <p>No bibs for this heat</p>;
    }

    const onSubmit: SubmitHandler<HeatTargetJudgeArtefactArray> = (dataArray) => {
        console.log({ id: phase_id, data: dataArray });
        const validArtefacts = {
            artefacts: dataArray.artefacts.filter(a => {
                if (!a?.artefact?.artefact_type) return false;
                if (!a?.artefact?.artefact_data) return false;

                // keep if at least one criterion is non-empty
                if (a?.artefact?.artefact_type === "ranking") {
                    return !a?.artefact?.artefact_data;
                }
                const hasValidData = a.artefact.artefact_data.some(d => d !== undefined && d !== null);
                return hasValidData;
            })
        };
        mutateArtefacts({ id: phase_id, idJudge: judge_id, data: validArtefacts })
    };

    return (
        <FormProvider {...formObject}>
            <form onSubmit={handleSubmit(onSubmit)} >
                <table>
                    <tbody>
                        <tr>
                            <th>Target</th>
                            {phase.judge_artefact_descr.artefact === "yan" &&
                                phase.judge_artefact_descr.artefact_data.map((criterion, index) => {
                                    return (
                                        <th key={`yan.${index}`}>
                                            {criterion}
                                        </th>
                                    );
                                })}
                            {phase.judge_artefact_descr.artefact === "ranking" &&
                                <th>Rank</th>
                            }
                        </tr>
                        {fields && fields.map((field, index) => (
                            <tr key={field.id}>
                                <td>
                                    {iter_target_dancers(bib_list[index].target) && iter_target_dancers(bib_list[index].target).map((i) => (
                                        <DancerCell key={`bib.${bib_list[index]}.${index}`} id_dancer={i} />
                                    ))}
                                </td>
                                {phase.judge_artefact_descr.artefact && (
                                    <Field
                                        error={get(errors, `artefacts.${index}.artefact.artefact_type.message`)}
                                    >
                                        <input
                                            defaultValue={phase.judge_artefact_descr.artefact}
                                            type='hidden'
                                            {...register(`artefacts.${index}.artefact.artefact_type`
                                            )} />
                                    </Field>
                                )}
                                {phase.judge_artefact_descr.artefact === "yan" &&
                                    phase.judge_artefact_descr.artefact_data.map((_, c_index) => {
                                        return (
                                            <td>
                                                <Field
                                                    error={get(errors, `artefacts.${index}.message`)}
                                                >
                                                    <select
                                                        {...register(`artefacts.${index}.artefact.artefact_data.${c_index}`)}
                                                    >
                                                        {yan_values.concat([undefined]).map(key => {
                                                            return <option key={key} value={key}>{key}</option>;
                                                        })}
                                                    </select>
                                                </Field>
                                            </td>
                                        );
                                    })}
                            </tr>
                        ))}
                    </tbody>
                </table>
                {errors.root?.formValidation &&
                    <div className="error_message">⚠️ {errors.root.formValidation.message}</div>
                }

                {errors.root?.serverError &&
                    <div className="error_message">⚠️ {errors.root.serverError.message}</div>
                }

                <button type="submit" disabled={formObject.formState.isSubmitting}>
                    Mettre à jour les artefacts
                </button>
                <button
                    type="button"
                    disabled={formObject.formState.isSubmitting}
                    onClick={() => reset(artefactData)}>
                    Réinitialiser
                </button>

            </form>
        </FormProvider >
    );
}



export default function ArtefactForm() {

    let { id_phase, id_judge } = useParams();
    let id_phase_number = Number(id_phase) as PhaseId;
    let id_judge_number = Number(id_judge) as DancerId;

    const { data: phaseData, isSuccess: isSuccessPhase } = useGetApiPhaseId(id_phase_number);

    const { data: heat_list, isSuccess: isSuccessHeats } = useGetApiPhaseIdSinglesHeats(id_phase_number);

    const { data: dataBibs, isSuccess: isSuccessBibs } = useGetApiCompIdBibs(phaseData?.competition as CompetitionId);

    if (!isSuccessPhase) return <div>Chargement...</div>;
    if (!phaseData) return null;
    if (!isSuccessBibs) return <div>Chargement des bibs...</div>;
    if (!isSuccessHeats) return <div>Chargement des heats...</div>;

    //const followers = heat_list.heats.flatMap(v => (v.followers.flatMap(u => iter_target_dancers(u))));
    //const leaders = heat_list.heats.flatMap(v => (v.leaders.flatMap(u => u.target)));
    const get_bibs = (dancer_list: DancerId[]) => dataBibs?.bibs.filter(b => iter_target_dancers(b.target).map(dancer => dancer_list?.includes(dancer)).includes(true));

    return (
        <>
            {heat_list && heat_list.heats && heat_list.heats.map((v, heat_minus_one) => (
                <>
                    <h1>Heat {heat_minus_one + 1}</h1>
                    <p>Followers</p>
                    <ArtefactFormComponent
                        phase_id={id_phase_number}
                        phase={phaseData}
                        heat_number={heat_minus_one}
                        judge_id={id_judge_number}
                        bib_list={get_bibs(v.followers.flatMap(u => iter_target_dancers(u)))}
                    />
                    <p>Leaders</p>
                    <ArtefactFormComponent
                        phase_id={id_phase_number}
                        phase={phaseData}
                        heat_number={heat_minus_one}
                        judge_id={id_judge_number}
                        bib_list={get_bibs(v.leaders.flatMap(u => iter_target_dancers(u)))}
                    />
                </>
            ))}

        </>
    );
}
