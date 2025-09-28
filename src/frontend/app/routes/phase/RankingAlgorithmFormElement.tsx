import type { ArtefactDescription, Phase, RankingAlgorithm, RankingAlgorithmRanking, RankingYanWeighted, YanCriterionWeights } from '@hookgen/model';
import React, { useEffect, useState } from 'react';
import { get, useFieldArray, useFormContext } from 'react-hook-form';
import { Field } from '@routes/index/field';


const defaultYan: YanCriterionWeights = { yes: 3, alt: 2, no: 1 };
const defaultRanking: RankingAlgorithmRanking = { algorithm: "ranking", algorithm_name: "RPSS" };

function isPhaseCoherent(p: Phase) {
    const identical_artefact = p.head_judge_artefact_descr.artefact === p.judge_artefact_descr.artefact;
    const artefact_coherent_with_algorithm = (p.ranking_algorithm.algorithm === "ranking") ?
        p.judge_artefact_descr.artefact === "ranking" : p.judge_artefact_descr.artefact === "yan";
    return identical_artefact && artefact_coherent_with_algorithm;
}

export function RankingAlgorithmFormElement() {

    const {
        register,
        watch,
        control,
        formState: { errors, defaultValues },
        setValue,
    } = useFormContext();


    const judgesArtefactDescription = watch("judge_artefact_descr");
    const headJudgeArtefactDescription = watch("head_judge_artefact_descr");

    const ranking_algorithm_algorithm = watch("ranking_algorithm.algorithm");
    const default_algo = (defaultValues === undefined) ? undefined : (defaultValues as Phase).ranking_algorithm.algorithm;

    useEffect(() => {
        if (default_algo === undefined) return;
        if (ranking_algorithm_algorithm === default_algo) return;

        if (ranking_algorithm_algorithm === "ranking") {
            setValue("ranking_algorithm", defaultRanking satisfies RankingAlgorithmRanking);
        } else if (ranking_algorithm_algorithm === "Yan_weighted") {
            setValue("ranking_algorithm", {
                algorithm: "Yan_weighted",
                weights: Array(judgesArtefactDescription.artefact_data ? judgesArtefactDescription.artefact_data.length : 1).fill(defaultYan),
                head_weights: Array(headJudgeArtefactDescription.artefact_data ? judgesArtefactDescription.artefact_data.length : 1).fill(defaultYan),
            } satisfies RankingYanWeighted);
        }
    }, [ranking_algorithm_algorithm, setValue]);

    const { fields: j_fields } = useFieldArray({
        control: control,
        name: "ranking_algorithm.weights",
    });

    const { fields: hj_fields } = useFieldArray({
        control: control,
        name: "ranking_algorithm.head_weights",
    });

    return (
        <>
            <Field
                label="Type d'algorithme de ranking"
                //htmlFor="ranking_algorithm_algorithm"
                error={get(errors, "ranking_algorithm.algorithm.message")}
            >
                <select
                    {...register("ranking_algorithm.algorithm", {
                        required: "Algorithm is required",
                        validate: (value, formValues) =>
                            isPhaseCoherent(formValues as Phase) || "Algorithm inconsistent with artefact descriptions.",
                    })}
                >
                    {["Yan_weighted", "ranking"].map((key) => (
                        <option key={key} value={key}>
                            {key}
                        </option>
                    ))}
                </select>
            </Field>
            {ranking_algorithm_algorithm === 'Yan_weighted' &&
                <>
                    <p>Notation juges</p>
                    <table>
                        <thead>
                            <tr>
                                <th>Critère</th>
                                <th>Yes</th>
                                <th>Alt</th>
                                <th>No</th>
                            </tr>
                        </thead>
                        <tbody>
                            {judgesArtefactDescription.artefact === "yan" && j_fields && j_fields.map((key, index) => (
                                <tr key={key.id}>
                                    <td>{judgesArtefactDescription.artefact_data && judgesArtefactDescription.artefact_data[index]}</td>
                                    <td>
                                        <Field
                                            error={get(errors, `ranking_algorithm.weights.${index}.yes.message`)}
                                        >
                                            <input
                                                type="number"
                                                {...register(`ranking_algorithm.weights.${index}.yes`, {
                                                    required: "required",
                                                    valueAsNumber: true,
                                                })} />
                                        </Field>

                                    </td>
                                    <td>
                                        <Field
                                            error={get(errors, `ranking_algorithm.weights.${index}.alt.message`)}
                                        >
                                            <input
                                                type="number"
                                                {...register(`ranking_algorithm.weights.${index}.alt`, {
                                                    required: "required",
                                                    valueAsNumber: true,
                                                })} />
                                        </Field>

                                    </td>
                                    <td>
                                        <Field
                                            error={get(errors, `ranking_algorithm.weights.${index}.no.message`)}
                                        >
                                            <input
                                                type="number"
                                                {...register(`ranking_algorithm.weights.${index}.no`, {
                                                    required: "required",
                                                    valueAsNumber: true,
                                                })} />
                                        </Field>

                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                    <p>Notations head judge</p>
                    <table>
                        <thead>
                            <tr>
                                <th>Critère</th>
                                <th>Yes</th>
                                <th>Alt</th>
                                <th>No</th>
                            </tr>
                        </thead>
                        <tbody>
                            {headJudgeArtefactDescription.artefact === "yan" && hj_fields && hj_fields.map((key, index) => (
                                <tr key={key.id}>
                                    <td>{headJudgeArtefactDescription.artefact_data && headJudgeArtefactDescription.artefact_data[index]}</td>
                                    <td>
                                        <Field
                                            error={get(errors, `ranking_algorithm.head_weights.${index}.yes.message`)}
                                        >
                                            <input
                                                type="number"
                                                {...register(`ranking_algorithm.head_weights.${index}.yes`, {
                                                    required: "required",
                                                    valueAsNumber: true,
                                                })} />
                                        </Field>
                                    </td>
                                    <td>
                                        <Field
                                            error={get(errors, `ranking_algorithm.head_weights.${index}.alt.message`)}
                                        >
                                            <input
                                                type="number"
                                                {...register(`ranking_algorithm.head_weights.${index}.alt`, {
                                                    required: "required",
                                                    valueAsNumber: true,
                                                })} />
                                        </Field>
                                    </td>
                                    <td>
                                        <Field
                                            error={get(errors, `ranking_algorithm.head_weights.${index}.no.message`)}
                                        >
                                            <input
                                                type="number"
                                                {...register(`ranking_algorithm.head_weights.${index}.no`, {
                                                    required: "required",
                                                    valueAsNumber: true,
                                                })} />
                                        </Field>

                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </>
            }
            {ranking_algorithm_algorithm === 'ranking' &&
                <>
                    <div>
                        <label>Algorithm for Ranking:</label>
                        RPSS
                    </div>
                </>}
        </>
    );
}
