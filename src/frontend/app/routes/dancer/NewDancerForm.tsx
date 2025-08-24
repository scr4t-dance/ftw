import React, { useState } from 'react';
// import { useNavigate } from "react-router";

import { getGetApiDancersQueryKey, usePutApiDancer, usePatchApiDancerId, getGetApiDancerIdQueryKey } from '@hookgen/dancer/dancer';

import { DivisionsItem, type Dancer, type DancerId, type Date } from '@hookgen/model';

import { Link } from 'react-router';
import { QueryClient, useQueryClient } from '@tanstack/react-query';
import { Controller, useForm, type SubmitHandler, type UseFormReturn } from 'react-hook-form';
import { Field } from '../index/field';

function putOrPatchApi({ queryClient, id_dancer, formObject }: { queryClient: QueryClient, id_dancer?: DancerId, formObject: UseFormReturn<Dancer, any, Dancer> }) {

    const { setError, reset } = formObject;

    if (id_dancer) {

        const rawPatchDancerApi = usePatchApiDancerId({
            mutation: {
                onSuccess: (data) => {
                    queryClient.invalidateQueries({
                        queryKey: getGetApiDancerIdQueryKey(id_dancer),
                    });
                    reset();
                },
                onError: (err) => {
                    console.error('Error updating competition:', err);
                    setError("root.serverError", { message: 'Erreur lors de l’ajout de la compétition.' });
                }
            }
        });

        const patchDancerApi = {
            ...rawPatchDancerApi,
            mutate: ({ data }: { data: Dancer }) => rawPatchDancerApi.mutate({ id: id_dancer, data: data })
        };


        return patchDancerApi;

    }

    const putDancerApi = usePutApiDancer({
        mutation: {
            onSuccess: (data) => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiDancersQueryKey(),
                });
                reset();
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
                setError("root.serverError", { message: 'Erreur lors de l’ajout de la compétition.' });
            }
        }
    });

    return putDancerApi;




}

export function SaveDancerFormComponent({ dancer, id_dancer }: { dancer?: Dancer, id_dancer?: DancerId }) {



    const default_dancer = id_dancer ? dancer : (
        {
            last_name: '',
            first_name: '',
            as_leader: [DivisionsItem.None],
            as_follower: [DivisionsItem.None],
        } as Dancer);

    // const navigate = useNavigate();

    const formObject = useForm<Dancer>({
        defaultValues: default_dancer
    });
    const {
        register,
        handleSubmit,
        formState: { errors },
        control,
    } = formObject;

    const queryClient = useQueryClient();
    // Using the Orval hook to handle the PUT request

    const { mutate: updateDancer, isSuccess, variables } = putOrPatchApi({ queryClient, id_dancer, formObject });

    const onSubmit: SubmitHandler<Dancer> = (data) => {
        console.log(data);
        updateDancer({ data: data });
    };

    const formatDate = (date: Date | undefined): string => {
        if (date?.year && date?.month && date?.day) {
            return `${date.year}-${String(date.month).padStart(2, '0')}-${String(date.day).padStart(2, '0')}`;
        }
        return '';
    };

    const buttonText = id_dancer ? "Mise à jour" : "Nouveau";

    return (
        <>
            <form onSubmit={handleSubmit(onSubmit)}>

                {isSuccess &&
                    <div className="error_message">
                        <span>&#x26A0; </span>
                        Successfully added dancer "{variables.data.last_name} {variables.data.first_name}"
                    </div>
                }

                <Field label="Nom" error={errors.last_name?.message}>
                    <input {...register("last_name", {
                        required: true,
                    })} />
                </Field>

                <Field label="Prénom" error={errors.first_name?.message}>
                    <input {...register("first_name", {
                        required: true,
                    })} />
                </Field>

                <Field label="Email" error={errors.email?.message}>
                    <input {...register("email", {
                        required: true,
                    })} />
                </Field>

                <Field label="Date de naissance 2" error={errors.birthday?.message}>
                    <Controller
                        name="birthday"
                        control={control}
                        rules={{ required: 'La date anniversaire est requise. Vous avez le droit de mentir.' }}
                        render={({ field }) => (
                            <input
                                type="date"
                                value={field.value ? formatDate(field.value) : ''}
                                onChange={(e) => {
                                    const [year, month, day] = e.target.value
                                        .split('-')
                                        .map(Number);
                                    field.onChange({ year, month, day });
                                }}
                            />
                        )}
                    />
                </Field>

                <Field label="Division Follower" error={errors.as_follower?.message}>
                    <select {...register("as_follower.0", {
                        required: true,
                    })}>
                        {DivisionsItem && Object.keys(DivisionsItem).map(key => {
                            const value = DivisionsItem[key as keyof typeof DivisionsItem];
                            return <option key={key} value={value}>{value}</option>;
                        })}
                    </select>
                </Field>

                <Field label="Division leader" error={errors.as_leader?.message}>
                    <select {...register("as_leader.0", {
                        required: true,
                    })}>
                        {DivisionsItem && Object.keys(DivisionsItem).map(key => {
                            const value = DivisionsItem[key as keyof typeof DivisionsItem];
                            return <option key={key} value={value}>{value}</option>;
                        })}
                    </select>
                </Field>

                <button type="submit" >{buttonText}</button>

            </form>

        </>
    );
}


function NewDancerForm() {

    return (
        <>
            <Link to={`/dancers`}>
                Retourner à la liste des compétiteurices
            </Link>
            <h1>Ajouter un-e compétiteur-euse</h1>
            <SaveDancerFormComponent />
        </>
    );
}


export default NewDancerForm;