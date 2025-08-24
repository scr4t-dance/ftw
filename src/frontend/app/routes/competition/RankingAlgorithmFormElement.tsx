import type { ArtefactDescription, Phase, RankingAlgorithmRanking, RankingYanWeighted, YanCriterionWeights } from '@hookgen/model';
import React, { useEffect, useState } from 'react';
import { useFieldArray, useFormContext } from 'react-hook-form';
import { Field } from '../index/field';


export function RankingAlgorithmFormElement() {

    const {
        register,
        watch,
        reset,
        control,
        formState: { errors },
    } = useFormContext();


    const defaultYan: YanCriterionWeights = { yes: 3, alt: 2, no: 1 };
    const defaultRanking: RankingAlgorithmRanking = { algorithm: "ranking", algorithm_name: "SPSS" };

    const judgesArtefactDescription = watch("judge_artefact_descr") as ArtefactDescription;
    const headJudgeArtefactDescription = watch("head_judge_artefact_descr") as ArtefactDescription;

    const ranking_algorithm_algorithm = watch("ranking_algorithm.algorithm");

    function build_default_yan_weighted(j_description: ArtefactDescription, hj_description: ArtefactDescription): RankingYanWeighted {
        if (j_description.artefact !== "yan") {
            throw TypeError("judges artefact description must be a Yes/Alt/No");
        }

        if (hj_description.artefact !== "yan") {
            throw TypeError("head judge artefact description must be a Yes/Alt/No");
        }

        return {
            algorithm: "Yan_weighted",
            weights: Array(j_description.artefact_data.length).fill(defaultYan),
            head_weights: Array(hj_description.artefact_data.length).fill(defaultYan),
        };
    }

    useEffect(() => {
        // Reset the entire 'target' field when 'target.target_type' changes
        // or when an artefact description change
        reset((prevValues: Phase) => ({
            ...prevValues,
            ranking_algorithm: (ranking_algorithm_algorithm === "ranking" ?
                defaultRanking :
                build_default_yan_weighted(
                    judgesArtefactDescription, headJudgeArtefactDescription
                )
            )
        }));
    }, [ranking_algorithm_algorithm, judgesArtefactDescription.artefact, headJudgeArtefactDescription.artefact, reset]);

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
            <Field label="Type d'algorithme de ranking" error={errors.root?.message}>
                <select
                    {...register("ranking_algorithm.algorithm", { required: true })}
                >
                    {["Yan_weighted", "ranking"].map(key => {
                        return <option key={key} value={key}>{key}</option>;
                    })}
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
                                    <td>{judgesArtefactDescription.artefact_data[index]}</td>
                                    <td>
                                        <input
                                            type="number"
                                            {...register(`ranking_algorithm.weights.${index}.yes`, {
                                                required: true,
                                                valueAsNumber: true,
                                            })} />
                                    </td>
                                    <td>

                                        <input
                                            type="number"
                                            {...register(`ranking_algorithm.weights.${index}.alt`, {
                                                required: true,
                                                valueAsNumber: true,
                                            })} />
                                    </td>
                                    <td>
                                        <input
                                            type="number"
                                            {...register(`ranking_algorithm.weights.${index}.no`, {
                                                required: true,
                                                valueAsNumber: true,
                                            })} />
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
                                    <td>{headJudgeArtefactDescription.artefact_data[index]}</td>
                                    <td>
                                        <input
                                            type="number"
                                            {...register(`ranking_algorithm.head_weights.${index}.yes`, {
                                                required: true,
                                                valueAsNumber: true,
                                            })} />
                                    </td>
                                    <td>

                                        <input
                                            type="number"
                                            {...register(`ranking_algorithm.head_weights.${index}.alt`, {
                                                required: true,
                                                valueAsNumber: true,
                                            })} />
                                    </td>
                                    <td>
                                        <input
                                            type="number"
                                            {...register(`ranking_algorithm.head_weights.${index}.no`, {
                                                required: true,
                                                valueAsNumber: true,
                                            })} />
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
