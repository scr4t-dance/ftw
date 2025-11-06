import type { Route } from './+types/NewPhaseForm';
import React, { useEffect, useState } from 'react';
// import { useNavigate } from "react-router";

import { usePutApiPhase, getGetApiCompIdPhasesQueryKey, useGetApiCompIdPhases, getGetApiPhaseIdQueryOptions, getApiCompIdPhases, getApiPhaseId } from '@hookgen/phase/phase';

import type {
    Phase,
    CompetitionId,
    Competition,
    EventId,
    Event,
} from '@hookgen/model';
import { RoundItem } from "@hookgen/model";
import { FormProvider, useForm, type SubmitHandler } from 'react-hook-form';
import { dehydrate, QueryClient, useQueries, useQueryClient } from '@tanstack/react-query';
import { Field } from '@routes/index/field';
import { Link, useLocation } from 'react-router';
import { useGetApiCompId } from '@hookgen/competition/competition';

import { getGetApiEventIdCompsQueryOptions, useGetApiEventId } from '@hookgen/event/event';
import { getGetApiEventIdQueryOptions } from '@hookgen/event/event';
import { getGetApiCompIdQueryOptions } from '@hookgen/competition/competition';

type NewPhaseFormProps = {
    id_competition: CompetitionId,
    competition_data: Competition,
    availableRounds: RoundItem[]
};

export async function loader({ params }: Route.LoaderArgs) {

    const queryClient = new QueryClient();
    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;

    await queryClient.prefetchQuery(getGetApiEventIdQueryOptions(id_event));
    await queryClient.prefetchQuery(getGetApiEventIdCompsQueryOptions(id_event));
    await queryClient.prefetchQuery(getGetApiCompIdQueryOptions(id_competition));

    return { dehydratedState: dehydrate(queryClient) };
}



function NewPhaseForm({ id_competition, competition_data, availableRounds }: NewPhaseFormProps) {

    const location = useLocation();
    const url_new = location.pathname.includes("new") ? "../" : "";
    const url_phase = location.pathname.includes("phase") ? "" : "phases/";
    const url = url_new.concat(url_phase);

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
    return (
        <>
            <h1>Ajouter une phase</h1>
            <FormProvider {...formObject}>
                <form onSubmit={handleSubmit(onSubmit)}>
                    {isSuccess &&
                        <div className="success_message">
                            ✅ Phase "{round}" avec identifiant "{dataPhase}" ajoutée avec succès à la compétition {id_competition}.
                            <br />
                            <Link to={`${url}${dataPhase}`}>Accéder à la Phase</Link>
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

    const { data: competition_data, isSuccess: isSuccessCompetition } = useGetApiCompId(id_competition);


    const { data: event_data, isSuccess: isSuccessEvent } = useGetApiEventId((competition_data as Competition).event, {
        query:{enabled: !!competition_data}
    });
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

    if (!isSuccessCompetition) return <div>Chargement...</div>;
    if (!isSuccessEvent) return <div>Chargement...</div>;

    return (
        <>
            <h1>Evénement {event_data.name} / Competition {competition_data.name}</h1>
            <NewPhaseForm
                id_competition={id_competition}
                competition_data={competition_data}
                availableRounds={availableRounds} />

        </>
    )

}


export default function NewPhaseFormRoute({
    params
}: Route.ComponentProps) {

    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;

    return (
        <>
            <NewPhaseFormComponent id_competition={id_competition} />
        </>
    );
}
