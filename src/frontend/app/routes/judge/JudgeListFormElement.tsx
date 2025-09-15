import type { CouplePanel, DancerIdList, SinglePanel } from '@hookgen/model';
import React, { useEffect } from 'react';
import { get, useFieldArray, useFormContext } from 'react-hook-form';
import { Field } from '@routes/index/field';

type KeysOfType<T, ValueType> = {
    [K in keyof T]: T[K] extends ValueType ? K : never;
}[keyof T];
type JudgeListDescriptionKeys = KeysOfType<SinglePanel, DancerIdList> |
    KeysOfType<CouplePanel, DancerIdList>;

interface Props {
    artefact_description_name: JudgeListDescriptionKeys
}

export function JudgeListFormElement({ artefact_description_name }: Props) {

    const {
        register,
        watch,
        control,
        formState: { errors, defaultValues },
        setValue,
    } = useFormContext();

    const { fields, append, remove } = useFieldArray({
        control: control,
        name: `${artefact_description_name}.dancers`,
    });

    const artefactType = watch(`panel_type`);
    const propName = `${artefact_description_name}.dancers`;

    useEffect(() => {
        setValue(propName, { dancers: [] });
    }, [artefactType, setValue]);

    return (
        <table>
            <thead>
                <tr>
                    <th>DancerID</th>
                    <th>Prénom</th>
                    <th>Nom</th>
                </tr>
            </thead>
            <tbody>
                {fields && fields.map((key, index) => (
                    <tr key={key.id}>
                        <td>
                            <Field
                                error={get(errors, `${artefact_description_name}.dancers.${index}.message`)}
                            >
                                <input
                                    type="number" {...register(`${artefact_description_name}.dancers.${index}`,
                                        {
                                            required: "Name should not be empty",
                                            valueAsNumber: true,
                                        }
                                    )} />
                            </Field>
                            <button type="button" onClick={() => {
                                remove(index);
                            }}>Delete</button>

                        </td>
                        <td>yes</td>
                        <td>alt</td>
                    </tr>
                ))}
                <tr>
                    <td>
                        <button
                            type="button"
                            onClick={() => {
                                append(1);
                            }}
                        >
                            append
                        </button>
                    </td>
                </tr>
            </tbody>
        </table>
    );
}
