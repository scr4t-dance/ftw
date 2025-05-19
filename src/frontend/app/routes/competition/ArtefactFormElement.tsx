import type { ArtefactDescription, Phase } from '@hookgen/model';
import React, { useEffect, useState } from 'react';
import { useFieldArray, type UseFormReturn } from 'react-hook-form';
import { Field } from '../index/field';


interface Props {
    formObject: UseFormReturn<Phase, any, Phase>;
}

export function ArtefactFormElement({ formObject }: Props) {

    const {
        register,
        watch,
        reset,
        control,
        formState: { errors },
    } = formObject;

    const defaultYanArtefact: ArtefactDescription = { artefact: "yan", artefact_data: ["total"] };
    const defaultRankingArtefact: ArtefactDescription = { artefact: "ranking", artefact_data: null };

    const artefactType = watch("judge_artefact_descr.artefact");

    const { fields, append, remove } = useFieldArray<Phase, "judge_artefact_descr.artefact_data">({
        control:control,
        name: "judge_artefact_descr.artefact_data",
    });

    useEffect(() => {
        // Reset the entire 'target' field when 'target.target_type' changes
        reset((prevValues: Phase) => ({
            ...prevValues,
            judge_artefact_descr: (artefactType === "yan" ? defaultYanArtefact : defaultRankingArtefact)
        }));
    }, [artefactType, reset]);

    return (
        <>
            <Field label="Type d'artefact" error={errors.artefact?.message}>
                <select
                    {...register("artefact", { required: true })}
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
                        {artefact.artefact_data && artefact.artefact_data.map((key, index) => (
                            <tr key={index}>
                                <td>
                                    <input
                                        type="text"
                                        name={key}
                                        value={key || ''}
                                        onChange={(e) => handleYanCriterionChange(key, 'key', e.target.value)} />

                                </td>
                                <td>yes</td>
                                <td>alt</td>
                                <td>no</td>
                            </tr>
                        ))}
                        <tr>
                            <td>
                                <button type='button' onClick={(e) => handleYanCriterionChange('critere', 'newkey', 'critere')}>
                                    Add row
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
