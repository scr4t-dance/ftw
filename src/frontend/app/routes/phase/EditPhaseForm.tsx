import type { Route } from './+types/EditPhaseForm';
import React, { useEffect } from 'react';
// import { useNavigate } from "react-router";

import {
    getApiPhaseId, getGetApiPhaseIdQueryKey,
    useGetApiPhaseId, usePatchApiPhaseId
} from '@hookgen/phase/phase';
import type {
    CompetitionId,
    EventId,
    Phase,
    PhaseId
} from '@hookgen/model';
import { ArtefactFormElement } from '@routes/phase/ArtefactFormElement';
import { FormProvider, useForm, type SubmitHandler } from 'react-hook-form';
import { Field } from '@routes/index/field';
import { RankingAlgorithmFormElement } from '@routes/phase/RankingAlgorithmFormElement';
import { getApiEventId, getApiEventIdComps } from '@hookgen/event/event';
import { getApiCompId } from '@hookgen/competition/competition';
import { queryClient } from '~/queryClient';



export async function loader({ params }: Route.LoaderArgs) {

    let id_event = Number(params.id_event) as EventId;
    const event_data = await getApiEventId(id_event);
    const competition_list = await getApiEventIdComps(id_event);
    const id_competition = Number(params.id_competition) as CompetitionId;
    const competition_data = await getApiCompId(id_competition);
    const id_phase = Number(params.id_phase) as PhaseId;
    const phase_data = await getApiPhaseId(id_phase);
    return {
        id_event,
        id_competition,
        event_data,
        competition_list,
        competition_data,
        id_phase,
        phase_data,
    };
}


export function EditPhaseForm({ phase_id, phase_data }: { phase_id: PhaseId, phase_data: Phase }) {

    const { mutate: updatePhase, isSuccess: isSuccessPatch } = usePatchApiPhaseId({
        mutation: {
            onSuccess: (updatedPhase) => {

                console.log("Success callback", { id: phase_id, data: updatedPhase });
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

    const formObject = useForm<Phase>({
        mode: "onChange",
        defaultValues: phase_data,
    });

    // guard before form but after queries

    if (!phase_data) {
        return <div>❌ Impossible de charger la phase {phase_id}</div>;
    }
    const onSubmit: SubmitHandler<Phase> = (data) => {
        console.log({ id: phase_id, data: data });
        updatePhase({ id: phase_id, data: data });
    };

    const {
        handleSubmit,
        watch,
        setError,
        reset,
        formState: { errors },
    } = formObject;


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
                    <button type="button" disabled={formObject.formState.isSubmitting} onClick={() => reset(phase_data)}>
                        Réinitialiser
                    </button>

                </form>
            </FormProvider>
        </>
    );
}

export function EditPhaseFormComponent({ id_phase }: { id_phase: PhaseId }) {

    const { data: phase_data, isLoading: isLoadingGet, isSuccess } = useGetApiPhaseId(id_phase);

    if (isLoadingGet) return <div>Loading Phase {id_phase} data</div>;
    if (!isSuccess) return <div>Error loading Phase {id_phase} data</div>;

    return <EditPhaseForm phase_id={id_phase} phase_data={phase_data} />
}

export default function EditPhaseFormRoute({
    loaderData
}: Route.ComponentProps) {

    return <EditPhaseForm phase_id={loaderData.id_phase} phase_data={loaderData.phase_data} />

}
