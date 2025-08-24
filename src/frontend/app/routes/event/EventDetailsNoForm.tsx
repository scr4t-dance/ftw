import type { Route } from "./+types/EventDetailsNoForm"
import "~/styles/ContentStyle.css";

import React from 'react';
import { getApiEventId } from '@hookgen/event/event';

import { type EventId, type Date } from "@hookgen/model";
import CompetitionList from "~/routes/competition/CompetitionList";

export async function loader({ params }: Route.LoaderArgs) {

    let id_event_number = parseInt(params.id_event as string) as EventId;
    const eventQuery = await getApiEventId(id_event_number);
    return eventQuery;
}

export async function clientLoader({
    serverLoader,
    params,
}: Route.ClientLoaderArgs) {

    const id_event_number = parseInt(params.id_event as string) as EventId;
    const res = await getApiEventId(id_event_number);
    const serverData = await serverLoader();
    return { ...serverData, ...res };
}

// HydrateFallback is rendered while the client loader is running
export function HydrateFallback({ params }: Route.LoaderArgs) {
    return <div>Chargement de l'événement {params.id_event}...</div>;
}

function EventDetails({
    params,
    loaderData,
}: Route.ComponentProps) {

    const event = loaderData;

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
            <CompetitionList id_event={parseInt(params.id_event)} />
        </>
    );
}

export default EventDetails;