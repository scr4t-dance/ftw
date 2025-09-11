//import type { Route } from "./+types/EventDetails"
import "~/styles/ContentStyle.css";

import React from 'react';
import { useGetApiEventId } from '@hookgen/event/event';

import { type EventId, type Date } from "@hookgen/model";
import CompetitionList from "~/routes/competition/CompetitionList";
import NewCompetitionForm from "../competition/NewCompetitionForm";
import { useParams } from "react-router";


function EventDetails() {

    const { id_event } = useParams();
    const id_event_number = Number(id_event) as EventId;
    const { data: event, isLoading, isError, error } = useGetApiEventId(id_event_number);

    if (isLoading) return <p>Chargement de l'événement {id_event}.</p>;
    if (isError) return <p>Erreur chargement événement {error.message}.</p>;
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
            <CompetitionList id_event={id_event_number} />
            <NewCompetitionForm id_event={id_event_number} />
        </>
    );
}

export default EventDetails;