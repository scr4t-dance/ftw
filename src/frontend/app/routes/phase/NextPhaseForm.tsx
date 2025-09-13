import React from 'react';
// import { useNavigate } from "react-router";

import type {
    PhaseId,
    NextPhaseFormData,
} from '@hookgen/model';
import { FormProvider, useForm, type SubmitHandler } from 'react-hook-form';
import { useQueryClient } from '@tanstack/react-query';
import { Field } from '@routes/index/field';
import { getGetApiPhaseIdCouplesHeatsQueryKey, getGetApiPhaseIdHeatsQueryKey, getGetApiPhaseIdSinglesHeatsQueryKey, usePutApiPhaseIdPromote } from '~/hookgen/heat/heat';

export default function NextPhaseForm({ id_phase }: { id_phase: PhaseId }) {

    //const navigate = useNavigate();

    const formObject = useForm<NextPhaseFormData>();

    const {
        register,
        handleSubmit,
        formState: { errors, isSubmitSuccessful },
    } = formObject;

    const queryClient = useQueryClient();

    const { mutate: promotePhase } = usePutApiPhaseIdPromote({
        mutation: {
            onSuccess: (nextPhase) => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdCouplesHeatsQueryKey(nextPhase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdSinglesHeatsQueryKey(nextPhase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdHeatsQueryKey(nextPhase),
                });
            },
            onError: (err) => {
                console.error('Error creating phase:', err);
            }
        }
    });

    const onSubmit: SubmitHandler<NextPhaseFormData> = (data) => {
        promotePhase({ id: id_phase, data: data });
    };


    return (
        <>
            <FormProvider {...formObject}>
                <form onSubmit={handleSubmit(onSubmit)}>
                    {isSubmitSuccessful &&
                        <div className="success_message">
                            ✅ Dancers has been transfered to next phase
                        </div>
                    }

                    <Field
                        label="Nombre de Target à passer à la phase suivante"
                        error={errors.number_of_targets_to_promote?.message}
                    >
                        <input type='number'
                        {...register("number_of_targets_to_promote", {
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

                    <button type="submit" >Passer à la phase suivante</button>

                </form>
            </FormProvider>
        </>
    );
}
