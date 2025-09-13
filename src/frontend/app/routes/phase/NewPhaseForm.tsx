import React, { useEffect, useState } from 'react';
// import { useNavigate } from "react-router";

import { useGetApiEventIdComps, useGetApiEvents } from '@hookgen/event/event';
import { usePutApiPhase, getGetApiCompIdPhasesQueryKey, useGetApiCompIdPhases, useGetApiPhaseId, getGetApiPhaseIdQueryOptions } from '@hookgen/phase/phase';

import type {
    Phase, EventId,
    CompetitionId,
} from '@hookgen/model';
import { RoundItem } from "@hookgen/model";
import { FormProvider, useForm, type SubmitHandler } from 'react-hook-form';
import { useQueries, useQueryClient } from '@tanstack/react-query';
import { Field } from '@routes/index/field';
import { Link, useNavigate } from 'react-router';
import { useGetApiCompId } from '@hookgen/competition/competition';





export function NewPhaseForm({ default_competition }: { default_competition: CompetitionId }) {

    const navigate = useNavigate();

    console.log("NewPhaseForm", default_competition, "init");

    const formObject = useForm<Phase>({
        defaultValues: {
            competition: default_competition,
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

    const { data: dataComp } = useGetApiCompId(default_competition);


    const { data: dataPhasesList } = useGetApiCompIdPhases(default_competition);
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

    const [selectedEvent, setSelectedEvent] = useState<EventId | undefined>(undefined);

    useEffect(() => {
        if (dataComp?.event) {
            setSelectedEvent(dataComp.event);
        }
    }, [dataComp]);
    const { data: dataEventList } = useGetApiEvents();
    const event_list = dataEventList?.events;

    const { data: dataCompetitionList, isLoading: isLoadingCompList } = useGetApiEventIdComps(selectedEvent as EventId);

    const queryClient = useQueryClient();

    const { data: dataPhase, mutate: updatePhase, isSuccess } = usePutApiPhase({
        mutation: {
            onSuccess: () => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiCompIdPhasesQueryKey(default_competition),
                });
            },
            onError: (err) => {
                console.error('Error creating phase:', err);
                setError("root.serverError", { message: 'Erreur lors de l’ajout de la phase.' });
            }
        }
    });


    const onSubmit: SubmitHandler<Phase> = (data) => {
        console.log(data);
        updatePhase({ data: data });
    };


    if (isLoadingCompList) return <div>Chargement...</div>;
    const competition_list = dataCompetitionList?.competitions;
    const round = watch("round");
    return (
        <>
            <h1>Ajouter une phase</h1>
            <FormProvider {...formObject}>
                <form onSubmit={handleSubmit(onSubmit)}>
                    {isSuccess &&
                        <div className="success_message">
                            ✅ Phase "{round}" avec identifiant "{dataPhase}" ajoutée avec succès à la compétition {default_competition}.
                            <br />
                            <Link to={`/phases/${dataPhase}`}>Accéder à la Phase</Link>
                        </div>
                    }

                    <Field label="Evénement parent">
                        <select
                            value={selectedEvent ?? ""}
                            onChange={(e) => {
                                console.log("selected_event", e.target.value, selectedEvent);
                                const eventId = parseInt(e.target.value) as EventId;
                                setSelectedEvent(eventId);          // update local state
                                formObject.setValue("competition", NaN); // reset competition when event changes
                            }}
                        >
                            {event_list?.map((eventId, index) => (
                                <option key={index} value={eventId}>
                                    {eventId}
                                </option>
                            ))}
                        </select>
                    </Field>

                    <Field label="Compétition parent">
                        <select
                            {...register("competition", {
                                valueAsNumber: true,
                                required: true,
                                onBlur: (e) => {
                                    console.log("selected_comp", e.target.value, default_competition);
                                    const newCompId = parseInt(e.target.value) as CompetitionId;
                                    if (newCompId != default_competition) navigate(`/competitions/${newCompId}`);
                                }
                            })}
                        >
                            {competition_list && competition_list.map((compId, index) => (
                                <option key={index} value={compId}>{compId}</option>
                            ))}
                        </select>
                    </Field>

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
