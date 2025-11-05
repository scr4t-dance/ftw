import React, { useEffect } from 'react';
// import { useNavigate } from "react-router";

import type {
    PhaseId,
    NextPhaseFormData,
} from '@hookgen/model';
import { FormProvider, useForm, type SubmitHandler } from 'react-hook-form';
import { useQueryClient } from '@tanstack/react-query';
import { Field } from '@routes/index/field';
import { getGetApiPhaseIdCouplesHeatsQueryKey, getGetApiPhaseIdHeatsQueryKey,
    getGetApiPhaseIdSinglesHeatsQueryKey, usePutApiPhaseIdPromoteAll } from '@hookgen/heat/heat';
import { usePutApiPhaseIdPromote } from '@hookgen/ranking/ranking';

export default function NextPhaseForm({ id_phase, treshold_callback }: { id_phase: PhaseId, treshold_callback?: (treshold:number)=>void }) {

    //const navigate = useNavigate();

    const formObject = useForm<NextPhaseFormData>({defaultValues: {number_of_targets_to_promote:0}}
    );

    const {
        register,
        handleSubmit,
        watch,
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

    const treshold = watch("number_of_targets_to_promote");
    useEffect(() => {
        if (treshold_callback === undefined) return;
        treshold_callback(treshold);
    }, [treshold]);

    return (
        <div className='no-print'>
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
                            min: 0,
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
        </div>
    );
}
