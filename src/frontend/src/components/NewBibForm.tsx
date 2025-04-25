import React, { useState } from 'react';
// import { useNavigate } from "react-router";
import { useForm, SubmitHandler } from 'react-hook-form';

import { useGetApiEventIdComps, useGetApiEvents } from '../hookgen/event/event'
import { usePutApiCompIdBib, useGetApiCompId } from '../hookgen/competition/competition';

import {
    Competition, CompetitionId, KindItem, CategoryItem,
    Bib, SingleTarget, CoupleTarget, Target,
    RoleItem,
    EventId,
} from 'hookgen/model';

function NewBibForm({ default_competition = -1 }: { default_competition?: CompetitionId }) {

    // const navigate = useNavigate();

    const default_single_target: Target = { target_type: "single", target: { target: 1, role: [RoleItem.Follower] } };
    const default_couple_target: Target = { target_type: "couple", target: { follower: 1, leader: 2 } };

    const [bib, setBib] = useState<Bib>({
        competition: default_competition,
        bib: 100,
        target: default_single_target,
    });

    const [competitionValidationError, setBibValidationError] = useState('');

    // Using the Orval hook to handle the PUT request
    const { mutate: updateBib, isError, error, isSuccess } = usePutApiCompIdBib();

    const { data: dataCompetition } = useGetApiCompId(default_competition);
    const competition = dataCompetition?.data;
    const { data: dataCompetitionList } = useGetApiEventIdComps(competition?.event as EventId);
    const competition_list = dataCompetitionList?.data.competitions;
    const { data: dataEventList } = useGetApiEvents();
    const event_list = dataEventList?.data.events

    const {
        register,
        handleSubmit,
        watch,
        formState: { errors },
      } = useForm<Bib>()
      const onSubmit: SubmitHandler<Inputs> = (data) => console.log(data)



    // Handle changes to input fields
    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
        const { name, value } = e.target;

        console.log("handleInputChange", name, value)
        setBib((prevBib: Bib) => ({
            ...prevBib,
            [name]: value,
        }));

    };

    // Handle form submission
    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        setBibValidationError('')

        try {
            await updateBib({ id: default_competition, data: bib });
            console.log('Bib updated successfully!');
            console.log(bib);
        } catch (err) {
            if (err instanceof Error) {
                console.error('Error updating bib:', err.message);
                setBibValidationError(err.message);  // Use err.message
            } else {
                // Handle other unexpected error types (fallback to a generic error)
                console.error('Unexpected error:', err);
                setBibValidationError("An unexpected error occurred.");
            }
        }
    };

    return (
        <>
            <h1>Ajouter une compétition</h1>
            <form onSubmit={handleSubmit}>

                {isSuccess &&
                    <div className="error_message">
                        <span>&#x26A0; </span>
                        Successfully added bib
                    </div>
                }


                <div className="form_subelem">
                    <label>Evénement parent</label>
                    <select
                        name="event"
                        value={competition && competition.event}
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
                        value={bib.competition}
                        onChange={handleInputChange}
                        required>
                        {competition_list && competition_list.map((compId, index) => (
                            <option key={index} value={compId}>{compId}</option>
                        ))}
                    </select>
                </div>

                <div className="form_subelem">
                    <label>Dossard</label>
                    <input
                        type="number"
                        name="bib"
                        value={bib.bib}
                        onChange={handleInputChange}
                        required
                    />
                </div>

                {competitionValidationError !== '' &&
                    <div className="error_message">
                        <span>&#x26A0; </span>
                        {competitionValidationError}
                    </div>
                }
                {isError &&
                    <div className="error_message">
                        <span>&#x26A0; </span>
                        {error.message}
                    </div>
                }

                <button type="submit" >Valider l'événement</button>

            </form>
        </>
    );
}

export default NewBibForm;