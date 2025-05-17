import React, { useState } from 'react';
// import { useNavigate } from "react-router";

import { useGetApiEvents } from '../hookgen/event/event'
import { usePutApiComp } from '../hookgen/competition/competition';

import { Competition, EventId, KindItem, CategoryItem } from 'hookgen/model';

function NewCompetitionForm({default_event=-1} : {default_event?:EventId}) {

    // const navigate = useNavigate();

    const [competition, setCompetition] = useState<Competition>({
        event: default_event,
        name: '',
        kind: [KindItem.Jack_and_Jill],
        category: [CategoryItem.Novice],
        n_leaders: 50,
        n_follows: 50
    });

    const [competitionValidationError, setCompetitionValidationError] = useState('');

    // Using the Orval hook to handle the PUT request
    const { mutate: updateCompetition, isError, error, isSuccess } = usePutApiComp();

    const { data:dataEventList } = useGetApiEvents();
    const event_list = dataEventList?.data.events

    // Handle changes to input fields
    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
        const { name, value } = e.target;

        console.log("handleInputChange", name, value)
        if (name === 'kind' || name === 'category') {

            setCompetition((prevCompetition: Competition) => ({
                ...prevCompetition,
                [name]: [value],
            }));
        } else if(name === "event") {

            setCompetition((prevCompetition: Competition) => ({
                ...prevCompetition,
                [name]: Number(value),
            }));
        } else {
            setCompetition((prevCompetition: Competition) => ({
                ...prevCompetition,
                [name]: value,
            }));
        }
    };

    // Handle form submission
    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        if (!competition.kind || !competition.category) {
            setCompetitionValidationError("Le type et la categorie de compétition sont obligatoires.");
            return;
        }

        setCompetitionValidationError('')

        try {
            await updateCompetition({ data: competition });
            console.log('Competition updated successfully!');
            console.log(competition);
        } catch (err) {
            if (err instanceof Error) {
                console.error('Error updating competition:', err.message);
                setCompetitionValidationError(err.message);  // Use err.message
            } else {
                // Handle other unexpected error types (fallback to a generic error)
                console.error('Unexpected error:', err);
                setCompetitionValidationError("An unexpected error occurred.");
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
                        Successfully added competition "{competition.name}"
                    </div>
                }


                <div className="form_subelem">
                    <label>Evénement parent</label>
                    <select
                        name="event"
                        value={competition.event}
                        onChange={handleInputChange}
                        required>
                        {event_list && event_list.map((eventId, index) => (
                            <option key={index} value={eventId}>{eventId}</option>
                        ))}
                    </select>
                </div>

                <div className="form_subelem">
                    <label>Titre de la compétition</label>
                    <input
                        type="text"
                        name="name"
                        value={competition.name}
                        onChange={handleInputChange}
                        required
                    />
                </div>

                <div className="form_subelem">
                    <label>Type de compétition</label>
                    <select
                        name="kind"
                        value={competition.kind && competition.kind[0]}
                        onChange={handleInputChange}
                        required>
                        {KindItem && Object.keys(KindItem).map(key => {
                            const value = KindItem[key as keyof typeof KindItem];
                            return <option key={key} value={value}>{value}</option>;
                        })}
                    </select>
                </div>

                <div className="form_subelem">
                    <label>Catégorie de compétition</label>
                    <select
                        name="category"
                        value={competition.category && competition.category[0]}
                        onChange={handleInputChange}
                        required>
                        {CategoryItem && Object.keys(CategoryItem).map(key => {
                            const value = CategoryItem[key as keyof typeof CategoryItem];
                            return <option key={key} value={value}>{value}</option>;
                        })}
                    </select>
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

export default NewCompetitionForm;