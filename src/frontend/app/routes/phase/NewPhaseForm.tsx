import React, { useState } from 'react';
// import { useNavigate } from "react-router";

import { useGetApiEventIdComps, useGetApiEvents } from '@hookgen/event/event';
import { usePutApiPhase, getGetApiCompIdPhasesQueryKey } from '@hookgen/phase/phase';

import type {
    Phase, EventId, ArtefactDescription,
    CompetitionId
} from '@hookgen/model';
import { RoundItem } from "@hookgen/model";
import { ArtefactFormElement } from '@routes/competition/ArtefactFormElement';
import { useFieldArray, useForm, type SubmitHandler } from 'react-hook-form';
import { useQueryClient } from '@tanstack/react-query';
import { Field } from '@routes/index/field';

export function NewPhaseForm({ default_competition }: { default_competition: CompetitionId }) {


    console.log("NewPhaseForm", default_competition);

    // const navigate = useNavigate();
    const formObject = useForm<Phase>({
        defaultValues: {
            competition: default_competition,
            round: [RoundItem.Finals],
            judge_artefact_descr: { artefact: "yan", artefact_data: ["total"] },
            head_judge_artefact_descr: { artefact: "yan", artefact_data: ["total"] },
            ranking_algorithm: { algorithm: "Yan_weighted", weights:[{yes:3,alt:2,no:1}], head_weights:[{yes:3,alt:2,no:1}], }
        }
    });

    const {
        register,
        handleSubmit,
        control,
        watch,
        setError,
        formState: { errors },
    } = formObject;

    const [selectedEvent, setSelectedEvent] = useState<EventId>(1)

    const [phaseValidationError, setPhaseValidationError] = useState('');

    const { data: dataEventList } = useGetApiEvents();
    const event_list = dataEventList?.events;

    const { data: dataCompetitionList } = useGetApiEventIdComps(selectedEvent);
    const competition_list = dataCompetitionList?.competitions;

    const queryClient = useQueryClient();
    // Using the Orval hook to handle the PUT request
    const { mutate: updatePhase, isError, error, isSuccess } = usePutApiPhase({
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


    const round = watch("round");

    const { fields, append, remove } = useFieldArray({
        control: control,
        name: "judge_artefact_descr.artefact_data",
    });

    return (
        <>
            <h1>Ajouter une phase</h1>
            <form onSubmit={handleSubmit(onSubmit)}>

                {isSuccess &&
                    <div className="error_message">
                        <span>&#x26A0; </span>
                        Successfully added phase "{round}" to competition {default_competition}
                    </div>
                }

                <Field label="Compétition parent">
                    <select
                        {...register("competition", { valueAsNumber: true, required: true })}
                    >
                        {competition_list && competition_list.map((compId, index) => (
                            <option key={index} value={compId}>{compId}</option>
                        ))}
                    </select>
                </Field>

                <div className="form_subelem">
                    <label>Round de compétition</label>
                    <select
                        {...register("round.0", { required: true })}
                    >
                        {RoundItem && Object.keys(RoundItem).map(key => {
                            const value = RoundItem[key as keyof typeof RoundItem];
                            return <option key={key} value={value}>{value}</option>;
                        })}
                    </select>
                </div>

                <ul>
                    {fields.map((item, index) => (
                        <li key={item.id}>
                            <input {...register(`judge_artefact_descr.artefact_data.${index}`)} />
                            <button type="button" onClick={() => remove(index)}>Delete</button>
                        </li>
                    ))}
                </ul>
                <button
                    type="button"
                    onClick={() => append("criterion")}
                >
                    append
                </button>

                {phaseValidationError !== '' &&
                    <div className="error_message">
                        <span>&#x26A0; </span>
                        phaseValidationError
                        {phaseValidationError}
                    </div>
                }
                {isError &&
                    <div className="error_message">
                        <span>&#x26A0; </span>
                        <p>{error.message}</p>
                    </div>
                }

                <button type="submit" >Valider l'événement</button>

            </form>
        </>
    );
}
