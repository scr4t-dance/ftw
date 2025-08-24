import type { ArtefactDescription, Phase } from '@hookgen/model';
import React, { useEffect, useState } from 'react';
import { useFieldArray, useFormContext } from 'react-hook-form';
import { Field } from '../index/field';


interface Props {
    artefact_description_name: string
}

export function ArtefactFormElement({ artefact_description_name }: Props) {

    const {
        register,
        watch,
        reset,
        control,
        formState: { errors },
        setValue,
    } = useFormContext();

    const defaultYanArtefact: ArtefactDescription = { artefact: "yan", artefact_data: ["total"] };
    const defaultRankingArtefact: ArtefactDescription = { artefact: "ranking", artefact_data: null };

    const { fields, append, remove } = useFieldArray({
        control: control,
        name: `${artefact_description_name}.artefact_data`,
    });

    const artefactType = watch(`${artefact_description_name}.artefact`);

    useEffect(() => {
        // Reset the entire 'target' field when 'target.target_type' changes
        reset((prevValues: Phase) => ({
            ...prevValues,
            judge_artefact_descr: (artefactType === "yan" ? defaultYanArtefact : defaultRankingArtefact)
        }));
    }, [artefactType, reset]);

    return (
        <>
            <Field label="Type d'artefact" error={errors.root?.message}>
                <select
                    {...register(`${artefact_description_name}.artefact`, { required: true })}
                >
                    {["yan", "ranking"].map(key => {
                        return <option key={key} value={key}>{key}</option>;
                    })}
                </select>
            </Field>
            {artefactType === 'yan' &&
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
                        {fields && fields.map((key, index) => (
                            <tr key={key.id}>
                                <td>

                                    <input {...register(`${artefact_description_name}.artefact_data.${index}`)} />
                                    <button type="button" onClick={() => {
                                        remove(index);

                                        // also remove corresponding weight or head_weight
                                        if (artefact_description_name === "judge_artefact_descr") {
                                            const currentWeights = watch("ranking_algorithm.weights") || [];
                                            const newWeights = [...currentWeights];
                                            newWeights.splice(index, 1);
                                            setValue("ranking_algorithm.weights", newWeights);
                                        }

                                        if (artefact_description_name === "head_judge_artefact_descr") {
                                            const currentHeadWeights = watch("ranking_algorithm.head_weights") || [];
                                            const newHeadWeights = [...currentHeadWeights];
                                            newHeadWeights.splice(index, 1);
                                            setValue("ranking_algorithm.head_weights", newHeadWeights);
                                        }

                                    }}>Delete</button>

                                </td>
                                <td>yes</td>
                                <td>alt</td>
                                <td>no</td>
                            </tr>
                        ))}
                        <tr>
                            <td>
                                <button
                                    type="button"
                                    onClick={() => {
                                        append("criterion");

                                        // also remove corresponding weight or head_weight
                                        const defaultYanWeight = { yes: 3, alt: 2, no: 1 };
                                        if (artefact_description_name === "judge_artefact_descr") {
                                            const currentWeights = watch("ranking_algorithm.weights") || [];
                                            setValue("ranking_algorithm.weights", [...currentWeights, defaultYanWeight]);
                                        }

                                        if (artefact_description_name === "head_judge_artefact_descr") {
                                            const currentHeadWeights = watch("ranking_algorithm.head_weights") || [];
                                            const newHeadWeights = [...currentHeadWeights];
                                            setValue("ranking_algorithm.head_weights", [...newHeadWeights, defaultYanWeight]);
                                        }
                                    }}
                                >
                                    append
                                </button>
                            </td>
                        </tr>
                    </tbody>
                </table>}
            {artefactType === 'ranking' &&
                <>
                    <div>
                        <label>Algorithm for Ranking:</label>
                        RPSS
                    </div>
                </>}
        </>
    );
}
