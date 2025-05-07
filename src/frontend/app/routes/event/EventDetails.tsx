import "~/styles/ContentStyle.css";

import React from 'react';
import { useGetApiEventId } from '@hookgen/event/event';

import { type EventId, type Date } from "@hookgen/model";
import { useParams } from "react-router";
import NewCompetitionForm from "@routes/competition/NewCompetitionForm";
import CompetitionList from "@routes/competition/CompetitionList";

function EventDetails() {

    let { id_event } = useParams();
    let id_event_number = parseInt(id_event as string) as EventId;
    const { data, isLoading, isError, error } = useGetApiEventId(id_event_number);

    if (isLoading) return <div>Chargement...</div>;
    if (!data) return null;

    const event = data.data;

    if (isLoading) return <div>Chargement des événements...</div>;
    if (isError) return <div>Erreur: {(error as any).message}</div>;

    const formatDate = (date: Date | undefined): string => {
        if (date?.year && date?.month && date?.day) {
            return `${date.year}-${String(date.month).padStart(2, '0')}-${String(date.day).padStart(2, '0')}`;
        }
        return '';
    };

    console.log("Sending default_event:", id_event_number);
    return (
        <>
            <h1>{event?.name}</h1>
            <p>Date de début : {formatDate(event?.start_date)}</p>
            <p>Date de fin : {formatDate(event?.end_date)}</p>
            <CompetitionList id_event={id_event_number} />
            <NewCompetitionForm id_event={id_event_number} />
        </>
    );
}

export default EventDetails;