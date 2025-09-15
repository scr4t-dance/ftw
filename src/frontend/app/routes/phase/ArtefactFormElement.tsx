import type { ArtefactDescription, Phase } from '@hookgen/model';
import React, { useEffect } from 'react';
import { get, useFieldArray, useFormContext } from 'react-hook-form';
import { Field } from '../index/field';

type KeysOfType<T, ValueType> = {
    [K in keyof T]: T[K] extends ValueType ? K : never;
}[keyof T];
type PhaseArtefactDescriptionKeys = KeysOfType<Phase, ArtefactDescription>;


const defaultYanWeight = { yes: 3, alt: 2, no: 1 };

const ArtefactDescriptionToWeightsMap = {
    judge_artefact_descr: "weights",
    head_judge_artefact_descr: "head_weights",
};

interface Props {
    artefact_description_name: PhaseArtefactDescriptionKeys
}

function isPhaseCoherent(p: Phase) {
    const identical_artefact = p.head_judge_artefact_descr.artefact === p.judge_artefact_descr.artefact;
    const artefact_coherent_with_algorithm = (p.ranking_algorithm.algorithm === "ranking") ?
        p.judge_artefact_descr.artefact === "ranking" : p.judge_artefact_descr.artefact === "yan";
    return identical_artefact && artefact_coherent_with_algorithm;
}


export function ArtefactFormElement({ artefact_description_name }: Props) {

    const {
        register,
        watch,
        control,
        formState: { errors, defaultValues },
        setValue,
        getValues,
    } = useFormContext();

    const defaultYanArtefact: ArtefactDescription = { artefact: "yan", artefact_data: ["total"] };
    const defaultRankingArtefact: ArtefactDescription = { artefact: "ranking", artefact_data: null };

    const { fields, append, remove } = useFieldArray({
        control: control,
        name: `${artefact_description_name}.artefact_data`,
    });

    const artefactType = watch(`${artefact_description_name}.artefact`);
    const propName = `ranking_algorithm.${ArtefactDescriptionToWeightsMap[artefact_description_name]}`;
    const currentWeights = watch(propName) || [];

    useEffect(() => {
        setValue(
            `${artefact_description_name}.artefact_data`,
            artefactType === "yan"
                ? defaultYanArtefact.artefact_data
                : defaultRankingArtefact.artefact_data,
            { shouldValidate: true, shouldDirty: true }
        );
        setValue(propName, [defaultYanWeight]);
    }, [artefactType, getValues, setValue]);

    return (
        <>
            <Field
                label="Type d'artefact"
                error={get(errors, `${artefact_description_name}.artefact.message`)}
            >
                <select
                    {...register(`${artefact_description_name}.artefact`, {
                        required: "required",
                        validate: (value, formValues) =>
                            isPhaseCoherent(formValues as Phase) || "Artefact description inconsistent with ranking algorithm.",
                    })}
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
                                    <Field
                                        error={get(errors, `${artefact_description_name}.artefact_data.${index}.message`)}
                                    >
                                        <input {...register(`${artefact_description_name}.artefact_data.${index}`,
                                            {
                                                required: "Name should not be empty"
                                            }
                                        )} />
                                    </Field>
                                    <button type="button" onClick={() => {
                                        remove(index);

                                        const newWeights = [...currentWeights];
                                        newWeights.splice(index, 1);
                                        setValue(propName, newWeights);

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

                                        // also add weights
                                        setValue(propName, [...currentWeights, defaultYanWeight]);
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
