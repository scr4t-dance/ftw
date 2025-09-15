import React, { useEffect, useState } from 'react';
// import { useNavigate } from "react-router";

import { getApiEventId, getApiEventIdComps, useGetApiEventIdComps, useGetApiEvents } from '@hookgen/event/event';
import { usePutApiPhase, getGetApiCompIdPhasesQueryKey, useGetApiCompIdPhases, useGetApiPhaseId, getGetApiPhaseIdQueryOptions, getApiCompIdPhases, getApiPhaseId } from '@hookgen/phase/phase';

import type {
    Phase, EventId,
    CompetitionId,
    Competition,
} from '@hookgen/model';
import { RoundItem } from "@hookgen/model";
import { FormProvider, useForm, type SubmitHandler } from 'react-hook-form';
import { useQueries, useQueryClient } from '@tanstack/react-query';
import { Field } from '@routes/index/field';
import { Link, useNavigate } from 'react-router';
import { getApiCompId, useGetApiCompId } from '@hookgen/competition/competition';
import type { Route } from './+types/NewPhaseForm';


type NewPhaseFormProps = {
    id_competition: CompetitionId,
    competition_data: Competition,
    availableRounds: RoundItem[]
};

export async function loader({ params }: Route.LoaderArgs) {

    let id_event = Number(params.id_event) as EventId;
    const event_data = await getApiEventId(id_event);
    const competition_list = await getApiEventIdComps(id_event);
    const id_competition = Number(params.id_competition) as CompetitionId;
    const competition_data = await getApiCompId(id_competition);
    const phase_list = await getApiCompIdPhases(id_competition);
    const phase_data_list = await Promise.all(
        phase_list.phases.map((id_phase) => getApiPhaseId(id_phase))
    );
    return {
        id_event,
        id_competition,
        event_data,
        competition_list,
        competition_data,
        phase_data_list,
    };
}

function NewPhaseForm({ id_competition, competition_data, availableRounds }: NewPhaseFormProps) {

    const formObject = useForm<Phase>({
        defaultValues: {
            competition: id_competition,
            round: [RoundItem.Finals],
            judge_artefact_descr: { artefact: "yan", artefact_data: ["total"] },
            head_judge_artefact_descr: { artefact: "yan", artefact_data: ["total"] },
            ranking_algorithm: { algorithm: "Yan_weighted", weights: [{ yes: 3, alt: 2, no: 1 }], head_weights: [{ yes: 3, alt: 2, no: 1 }], }
        }
    });

    const {
        register,
        handleSubmit,
        watch,
        setError,
        formState: { errors },
    } = formObject;


    const queryClient = useQueryClient();

    const { data: dataPhase, mutate: updatePhase, isSuccess } = usePutApiPhase({
        mutation: {
            onSuccess: () => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiCompIdPhasesQueryKey(id_competition),
                });
            },
            onError: (err) => {
                console.error('Error creating phase:', err);
                setError("root.serverError", { message: 'Erreur lors de l’ajout de la phase.' });
            }
        }
    });


    const onSubmit: SubmitHandler<Phase> = (data) => {
        updatePhase({ data: data });
    };

    const round = watch("round");
    const url = `/events/${competition_data.event}/competitions/${id_competition}`
    return (
        <>
            <h1>Ajouter une phase</h1>
            <FormProvider {...formObject}>
                <form onSubmit={handleSubmit(onSubmit)}>
                    {isSuccess &&
                        <div className="success_message">
                            ✅ Phase "{round}" avec identifiant "{dataPhase}" ajoutée avec succès à la compétition {id_competition}.
                            <br />
                            <Link to={`${url}/phases/${dataPhase}`}>Accéder à la Phase</Link>
                        </div>
                    }

                    <Field label='Round de compétition'>
                        <select
                            {...register("round.0", { required: true })}
                        >
                            {availableRounds && availableRounds.map(value => {
                                return <option key={value} value={value}>{value}</option>;
                            })}
                        </select>
                    </Field>

                    {errors.root?.formValidation &&
                        <div className="error_message">⚠️ {errors.root.formValidation.message}</div>
                    }

                    {errors.root?.serverError &&
                        <div className="error_message">⚠️ {errors.root.serverError.message}</div>
                    }

                    <button type="submit" >Créer la phase</button>

                </form>
            </FormProvider>
        </>
    );
}

export function NewPhaseFormComponent({ id_competition }: { id_competition: CompetitionId }) {

    const { data: competition_data, isSuccess } = useGetApiCompId(id_competition);
    const { data: dataPhasesList } = useGetApiCompIdPhases(id_competition);
    const phase_list = dataPhasesList?.phases;


    const phaseQueries = useQueries({
        queries: (phase_list ?? []).map((id) => {
            const options = getGetApiPhaseIdQueryOptions(id);
            return {
                queryKey: options.queryKey,
                queryFn: options.queryFn,
                enabled: !!id,
            };
        }),
    });

    const usedRounds = phaseQueries
        .map(q => q.data?.round)
        .filter(Boolean)
        .flat();

    const availableRounds = Object.values(RoundItem).filter(r => !usedRounds.includes(r));

    if (!isSuccess) return <div>Chargement...</div>;

    return (
        <NewPhaseForm
            id_competition={id_competition}
            competition_data={competition_data}
            availableRounds={availableRounds} />
    )

}


export default function NewPhaseFormRoute({
    loaderData
}: Route.ComponentProps) {

    const usedRounds = loaderData.phase_data_list
        .map(q => q.round)
        .filter(Boolean)
        .flat();

    const availableRounds = Object.values(RoundItem).filter(r => !usedRounds.includes(r));

    return (
        <>
            <h1>Evénement {loaderData.event_data.name} / Competition {loaderData.competition_data.name}</h1>
            <NewPhaseForm
                id_competition={loaderData.id_competition}
                competition_data={loaderData.competition_data}
                availableRounds={availableRounds} />
        </>
    );
}
