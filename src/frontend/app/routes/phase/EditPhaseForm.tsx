import React, { useEffect } from 'react';
// import { useNavigate } from "react-router";

import { getGetApiPhaseIdQueryKey, useGetApiPhaseId, usePatchApiPhaseId } from '@hookgen/phase/phase';

import type {
    Phase,
    PhaseId
} from '@hookgen/model';
import { ArtefactFormElement } from '@routes/competition/ArtefactFormElement';
import { FormProvider, useForm, type SubmitHandler } from 'react-hook-form';
import { useQueryClient } from '@tanstack/react-query';
import { Field } from '@routes/index/field';
import { RankingAlgorithmFormElement } from '../competition/RankingAlgorithmFormElement';

export function EditPhaseForm({ phase_id }: { phase_id: PhaseId }) {

    const queryClient = useQueryClient();

    const { data: dataPhase, isLoading: isLoadingGet, isSuccess } = useGetApiPhaseId(phase_id);

    const { mutate: updatePhase, isSuccess: isSuccessPatch } = usePatchApiPhaseId({
        mutation: {
            onSuccess: (updatedPhase) => {

                console.log("p,Success callback", { id: phase_id, data: updatedPhase });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdQueryKey(phase_id),
                });

                //reset(updatedPhase);
                //queryClient.setQueryData(getGetApiPhaseIdQueryKey(phase_id), updatedPhase)
            },
            onError: (err) => {
                console.error('Error creating phase:', err);
                setError("root.serverError", { message: 'Erreur lors de l’ajout de la phase.' });
            }
        }
    });

    // guard before form but after queries
    if (isLoadingGet) return <div>Loading Phase {phase_id} data</div>;

    if (!dataPhase) {
        return <div>❌ Impossible de charger la phase {phase_id}</div>;
    }
    const onSubmit: SubmitHandler<Phase> = (data) => {
        console.log({ id: phase_id, data: data });
        updatePhase({ id: phase_id, data: data });
    };

    const formObject = useForm<Phase>({
        disabled: isLoadingGet,
        mode: "onChange",
        defaultValues: dataPhase,
    });

    const {
        handleSubmit,
        watch,
        setError,
        reset,
        formState: { errors, isValid },
    } = formObject;

    useEffect(() => {
        if (isSuccess && dataPhase) {
            formObject.reset(dataPhase);
        }
    }, [isSuccess, dataPhase, formObject]);

    const round = watch("round");


    return (
        <>
            <h1>Modifier la phase</h1>
            <FormProvider {...formObject}>
                <form onSubmit={handleSubmit(onSubmit)}>
                    {isSuccessPatch &&
                        <div className="success_message">
                            ✅ Phase "{round}" avec identifiant "{phase_id}" mis à jour avec succès.
                        </div>
                    }

                    <h2>Artefact Juges</h2>
                    <ArtefactFormElement artefact_description_name='judge_artefact_descr' />
                    <h2>Artefact Head Juges</h2>
                    <ArtefactFormElement artefact_description_name='head_judge_artefact_descr' />

                    <Field label='Algorithme de ranking'>
                        <RankingAlgorithmFormElement />
                    </Field>

                    {errors.root?.formValidation &&
                        <div className="error_message">⚠️ {errors.root.formValidation.message}</div>
                    }

                    {errors.root?.serverError &&
                        <div className="error_message">⚠️ {errors.root.serverError.message}</div>
                    }

                    <button type="submit" disabled={formObject.formState.isSubmitting}>
                        Mettre à jour la phase
                    </button>
                    <button type="button" disabled={formObject.formState.isSubmitting} onClick={() => reset(dataPhase)}>
                        Réinitialiser
                    </button>

                </form>
            </FormProvider>
        </>
    );
}
