import React from 'react';
// import { useNavigate } from "react-router";

import type {
    PhaseId,
    InitHeatsFormData,
} from '@hookgen/model';
import { FormProvider, useForm, type SubmitHandler } from 'react-hook-form';
import { useQueryClient } from '@tanstack/react-query';
import { Field } from '@routes/index/field';
import { getGetApiPhaseIdCouplesHeatsQueryKey, getGetApiPhaseIdHeatsQueryKey, getGetApiPhaseIdSinglesHeatsQueryKey, usePutApiPhaseIdInitHeats } from '~/hookgen/heat/heat';

export function InitHeatsForm({ id_phase }: { id_phase: PhaseId }) {

    //const navigate = useNavigate();

    const formObject = useForm<InitHeatsFormData>({
        defaultValues:{
            min_number_of_targets: 0,
            max_number_of_targets: 0,
            early_heat_range: 1,
            early_heat_ids:"",
            late_heat_range:1,
            late_heat_ids:"",
        }
    });

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
                // load all_judges in server after merging change_api_loading
                // all_judges.map((judge_id) => (queryClient.invalidateQueries({
                //         queryKey: getGetApiPhaseIdArtefactJudgeIdJudgeQueryKey(id_phase, judge_id),
                //     })));
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


                    <Field
                        label="Nombre de Heats dans lesquelles placer les Targets passant en dernier"
                        error={errors.late_heat_range?.message}
                    >
                        <input type='number'
                            {...register("late_heat_range", {
                                required: "Should be a number",
                                min: 0,
                                valueAsNumber: true,
                            })} />
                    </Field>


                    <Field
                        label="Id des targets devant passer en dernier"
                        error={errors.late_heat_ids?.message}
                    >
                        <input
                            {...register("late_heat_ids", {
                            })} />
                    </Field>

                    <Field
                        label="Nombre de Heats dans lesquelles placer les Targets passant en premier"
                        error={errors.early_heat_range?.message}
                    >
                        <input type='number'
                            {...register("early_heat_range", {
                                required: "Should be a number",
                                min: 0,
                                valueAsNumber: true,
                            })} />
                    </Field>


                    <Field
                        label="Id des targets devant passer en dernier"
                        error={errors.early_heat_ids?.message}
                    >
                        <input
                            {...register("early_heat_ids", {
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
