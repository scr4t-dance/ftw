import type { CouplePanel, DancerId, DancerIdList, SinglePanel } from '@hookgen/model';
import React, { useEffect } from 'react';
import { Controller, get, useFieldArray, useFormContext } from 'react-hook-form';
import { Field } from '@routes/index/field';
import { useGetApiDancerId } from '~/hookgen/dancer/dancer';
import { Link } from 'react-router';

type KeysOfType<T, ValueType> = {
    [K in keyof T]: T[K] extends ValueType ? K : never;
}[keyof T];
type JudgeListDescriptionKeys = KeysOfType<SinglePanel, DancerIdList> |
    KeysOfType<CouplePanel, DancerIdList>;

interface Props {
    artefact_description_name: JudgeListDescriptionKeys
}

export function DancerCell({ id_dancer }: { id_dancer: DancerId }) {

    const { data: dancer } = useGetApiDancerId(id_dancer);

    if (!dancer) return "Loading dancer..."

    return (
        <>
            <td>
                <Link to={`/admin/dancers/${id_dancer}`}>
                    {dancer.first_name}
                </Link>
            </td>
            <td>
                <Link to={`/admin/dancers/${id_dancer}`}>
                    {dancer.last_name}
                </Link>
            </td>
        </>
    )
}

export function JudgeListFormElement({ artefact_description_name }: Props) {

    const {
        register,
        watch,
        control,
        getValues,
        formState: { errors, defaultValues },
    } = useFormContext();

    const { fields, append, remove } = useFieldArray({
        control: control,
        name: `${artefact_description_name}.dancers`,
    });

    const watchFieldArray = watch(`${artefact_description_name}.dancers`);
    const controlledFields = fields.map((field, index) => {
        return {
            ...field,
            ...watchFieldArray[index],
        };
    })


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
                {fields && fields.map((item, index) => (
                    <tr key={item.id}>
                        <Controller
                            name={`${artefact_description_name}.dancers.${index}`}
                            render={({ field }) => (
                                <>
                                    <td>
                                        <Field
                                            error={get(errors, `${artefact_description_name}.dancers.${index}.message`)}
                                        >
                                            <input type="number"
                                value={Number(field.value)}
                                onChange={(e) => {
                                    field.onChange(e.target.value);
                                }}
                                            />
                                        </Field>
                                        <button type="button" onClick={() => {
                                            remove(index);
                                        }}>
                                            Delete
                                        </button>

                                    </td>
                                    <DancerCell id_dancer={field.value} />
                                </>
                            )}
                            control={control} />

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
