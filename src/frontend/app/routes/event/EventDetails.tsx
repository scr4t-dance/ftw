import type { Route } from "./+types/EventDetails"

import React from 'react';
import { getApiEventId } from '@hookgen/event/event';

import { type EventId, type Date } from "@hookgen/model";
import NewCompetitionForm from "@routes/competition/NewCompetitionForm";
import { Link } from "react-router";

export async function loader({ params }: Route.LoaderArgs) {
    const id_event_number = Number(params.id_event) as EventId;
    const event_data = await getApiEventId(id_event_number);

    return {
        id_event:id_event_number,
        event_data,
    };
}

export default function EventDetails({
    loaderData,
}: Route.ComponentProps) {

    const id_event = loaderData.id_event;
    const event = loaderData.event_data;

    if (!event) return <p>Pas de données sur l’événement {id_event}.</p>;

    const formatDate = (date: Date | undefined): string => {
        if (date?.year && date?.month && date?.day) {
            return `${date.year}-${String(date.month).padStart(2, '0')}-${String(date.day).padStart(2, '0')}`;
        }
        return '';
    };

    return (
        <>
            <h1>{event?.name}</h1>
            <p>Date de début : {formatDate(event?.start_date)}</p>
            <p>Date de fin : {formatDate(event?.end_date)}</p>
            <Link to={`/events/${id_event}/competitions/new`}>Créer une competition</Link>
            <Link to={`/events/${id_event}/competitions`}>Liste des competitions</Link>
        </>
    );
}
