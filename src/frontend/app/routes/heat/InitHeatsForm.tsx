import React from 'react';
// import { useNavigate } from "react-router";

import type {
    PhaseId,
    InitHeatsFormData,
} from '@hookgen/model';
import { FormProvider, useForm, type SubmitHandler } from 'react-hook-form';
import { useQueryClient } from '@tanstack/react-query';
import { Field } from '@routes/index/field';
import { getGetApiPhaseIdCouplesHeatsQueryKey, getGetApiPhaseIdHeatsQueryKey, getGetApiPhaseIdSinglesHeatsQueryKey, usePutApiPhaseIdInitHeats, usePutApiPhaseIdPromote } from '~/hookgen/heat/heat';

export function InitHeatsForm({ id_phase }: { id_phase: PhaseId }) {

    //const navigate = useNavigate();

    const formObject = useForm<InitHeatsFormData>();

    const {
        register,
        handleSubmit,
        setError,
        formState: { errors, isSubmitSuccessful },
    } = formObject;

    const queryClient = useQueryClient();

    const { mutate: initHeats } = usePutApiPhaseIdInitHeats({
        mutation: {
            onSuccess: () => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdCouplesHeatsQueryKey(id_phase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdSinglesHeatsQueryKey(id_phase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdHeatsQueryKey(id_phase),
                });
            },
            onError: (err) => {
                console.error('Error creating phase:', err);
                //setError(err);
            }
        }
    });

    const onSubmit: SubmitHandler<InitHeatsFormData> = (data) => {
        initHeats({ id: id_phase, data: data });
    };


    return (
        <>
            <FormProvider {...formObject}>
                <form onSubmit={handleSubmit(onSubmit)}>
                    {isSubmitSuccessful &&
                        <div className="success_message">
                            ✅ Dancers has been added distributed to heats
                        </div>
                    }

                    <Field
                        label="Nombre minimal de Targets"
                        error={errors.min_number_of_targets?.message}
                    >
                        <input type='number'
                        {...register("min_number_of_targets", {
                            required: "Should be a number",
                            valueAsNumber: true,
                        })} />
                    </Field>

                    <Field
                        label="Nombre maximal de Targets"
                        error={errors.max_number_of_targets?.message}
                    >
                        <input type='number'
                        {...register("max_number_of_targets", {
                            required: "Should be a number",
                            valueAsNumber: true,
                        })} />
                    </Field>

                    {errors.root?.formValidation &&
                        <div className="error_message">⚠️ {errors.root.formValidation.message}</div>
                    }

                    {errors.root?.serverError &&
                        <div className="error_message">⚠️ {errors.root.serverError.message}</div>
                    }

                    <button type="submit" >Initialiser les Heats</button>

                </form>
            </FormProvider>
        </>
    );
}
