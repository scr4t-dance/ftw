import React, { useState } from 'react';
// import { useNavigate } from "react-router";

import { usePutApiEvent } from '@hookgen/event/event';

import type { Event, Date } from '@hookgen/model';

function NewEventForm() {

    // const navigate = useNavigate();

    const [event, setEvent] = useState<Event>({
        name: '',
        start_date: { day: 0, month: 0, year: 0 },
        end_date: { day: 0, month: 0, year: 0 },
    });

    const formatDate = (date: Date | undefined): string => {
        if (date?.year && date?.month && date?.day) {
            return `${date.year}-${String(date.month).padStart(2, '0')}-${String(date.day).padStart(2, '0')}`;
        }
        return '';
    };

    const [eventValidationError, setEventValidationError] = useState('');

    // Using the Orval hook to handle the PUT request
    const { mutate: updateEvent, isError, error, isSuccess } = usePutApiEvent();

    // Handle changes to input fields
    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const { name, value } = e.target;

        // Convert the date string into day, month, year if the field is for a date
        if (name === 'start_date' || name === 'end_date') {
            const [year, month, day] = value.split('-').map(Number);  // Split the YYYY-MM-DD value

            setEvent((prevEvent: Event) => ({
                ...prevEvent,
                [name]: { day, month, year },
            }));
        } else {
            setEvent((prevEvent: Event) => ({
                ...prevEvent,
                [name]: value,
            }));
        }
    };

    // Handle form submission
    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        if (!event.start_date || !event.end_date) {
            setEventValidationError("La date de début et la date de fin sont obligatoires.");
            return;
        }

        if (event.start_date > event.end_date) {
            setEventValidationError("La date de début doit être antérieure à la date de fin.")
            return;
        }

        setEventValidationError('')

        try {
            await updateEvent({ data: event });
            console.log('Event updated successfully!');
        } catch (err) {
            if (err instanceof Error) {
                console.error('Error updating event:', err.message);
                setEventValidationError(err.message);  // Use err.message
            } else {
                // Handle other unexpected error types (fallback to a generic error)
                console.error('Unexpected error:', err);
                setEventValidationError("An unexpected error occurred.");
            }
        }
    };

    return (
        <>
            <h1>Ajouter un événement</h1>
            <form onSubmit={handleSubmit}>

                {isSuccess &&
                    <div className="error_message">
                        <span>&#x26A0; </span>
                        Successfully added event "{event.name}"
                    </div>
                }

                <div className="form_subelem">
                    <label>Titre de l'événement</label>
                    <input
                        type="text"
                        name="name"
                        value={event.name}
                        onChange={handleInputChange}
                        required
                    />
                </div>

                <div className="form_subelem">
                    <label>Début de l'événement</label>
                    <input
                        type="date"
                        name="start_date"
                        value={formatDate(event.start_date)}
                        onChange={handleInputChange}
                        required
                    />
                </div>

                <div className="form_subelem">
                    <label>Fin de l'événement</label>
                    <input
                        type="date"
                        name="end_date"
                        value={formatDate(event.end_date)}
                        onChange={handleInputChange}
                        required
                    />
                </div>

                {eventValidationError !== '' &&
                    <div className="error_message">
                        <span>&#x26A0; </span>
                        {eventValidationError}
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

export default NewEventForm;