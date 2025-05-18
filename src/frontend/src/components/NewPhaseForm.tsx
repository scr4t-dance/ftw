import React, { useState } from 'react';
// import { useNavigate } from "react-router";

import { useGetApiEventIdComps, useGetApiEvents } from '../hookgen/event/event';
import { usePutApiPhase } from '../hookgen/phase/phase';

import {
    Phase, EventId, RoundItem, ArtefactDescription,
    CompetitionId
} from 'hookgen/model';
import { ArtefactFormElement } from './ArtefactFormElement';
import { AxiosError } from 'axios';

function NewPhaseForm({ default_competition = -1 }: { default_competition?: CompetitionId }) {

    // const navigate = useNavigate();

    const [phase, setPhase] = useState<Phase>({
        competition: default_competition,
        round: [RoundItem.Finals],
        judge_artefact_descr: {artefact:"ranking", artefact_data: null},
        head_judge_artefact_descr: {artefact:"ranking", artefact_data: null},
    });

    const [selectedEvent, setSelectedEvent] = useState<EventId>(1)

    const [phaseValidationError, setPhaseValidationError] = useState('');

    // Using the Orval hook to handle the PUT request
    const { mutate: updatePhase, isError, error, isSuccess } = usePutApiPhase();

    const { data: dataEventList } = useGetApiEvents();
    const event_list = dataEventList?.data.events

    const { data: dataCompetitionList } = useGetApiEventIdComps(selectedEvent);
    const competition_list = dataCompetitionList?.data.competitions;

    // Handle changes to input fields
    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
        const { name, value } = e.target;

        console.log("handleInputChange", name, value)

        if (name === 'round') {

            setPhase((prevPhase: Phase) => ({
                ...prevPhase,
                [name]: [value as RoundItem],
            }));
        } else if (name === 'event') {
            setSelectedEvent(Number(value));
        } else if (name === "competition") {

            setPhase((prevPhase: Phase) => ({
                ...prevPhase,
                [name]: Number(value),
            }));
        } else {
            setPhase((prevPhase: Phase) => ({
                ...prevPhase,
                [name]: value,
            }));
        }

    };

    // Handle form submission
    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        if (!phase.round) {
            setPhaseValidationError("Le type et la categorie de compétition sont obligatoires.");
            return;
        }

        setPhaseValidationError('')

        try {
            await updatePhase({ data: phase });
            console.log('Phase updated successfully!');
            console.log(phase);
        } catch (err) {
            // If AxiosError is caught, extract the error message
            if (isError && error instanceof AxiosError) {
                console.error("Axios");
                const errorMessage = error?.response?.data?.message || 'An unknown error occurred';
                console.error(errorMessage);
            } else if (err instanceof Error) {
                console.error('Error updating phase:', err.message);
                setPhaseValidationError(err.message);  // Use err.message
            } else {
                // Handle other unexpected error types (fallback to a generic error)
                console.error('Unexpected error:', err);
                setPhaseValidationError("An unexpected error occurred.");
            }
        }
    };

    return (
        <>
            <h1>Ajouter une phase</h1>
            <form onSubmit={handleSubmit}>

                {isSuccess &&
                    <div className="error_message">
                        <span>&#x26A0; </span>
                        Successfully added phase "{phase.round}" to competition {phase.competition}
                    </div>
                }


                <div className="form_subelem">
                    <label>Evénement parent</label>
                    <select
                        name="event"
                        value={selectedEvent}
                        onChange={handleInputChange}
                        required>
                        {event_list && event_list.map((eventId, index) => (
                            <option key={index} value={eventId}>{eventId}</option>
                        ))}
                    </select>
                </div>

                <div className="form_subelem">
                    <label>Compétition parent</label>
                    <select
                        name="competition"
                        value={phase.competition}
                        onChange={handleInputChange}
                        required>
                        {competition_list && competition_list.map((compId, index) => (
                            <option key={index} value={compId}>{compId}</option>
                        ))}
                    </select>
                </div>

                <div className="form_subelem">
                    <label>Round de compétition</label>
                    <select
                        name="round"
                        value={phase.round && phase.round[0]}
                        onChange={handleInputChange}
                        required>
                        {RoundItem && Object.keys(RoundItem).map(key => {
                            const value = RoundItem[key as keyof typeof RoundItem];
                            return <option key={key} value={value}>{value}</option>;
                        })}
                    </select>
                </div>

                <label>judge_artefact_description</label>
                <ArtefactFormElement
                    attribute_name="judge_artefact_description"
                    artefact_value={phase.judge_artefact_descr as ArtefactDescription}
                    callback={setPhase}
                />

                <label>head_judge_artefact_description</label>
                <ArtefactFormElement
                    attribute_name="head_judge_artefact_description"
                    artefact_value={phase.head_judge_artefact_descr as ArtefactDescription}
                    callback={setPhase}
                />

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
                        <p>{error.response?.data.message}</p>
                    </div>
                }

                <button type="submit" >Valider l'événement</button>

            </form>
        </>
    );
}

export default NewPhaseForm;