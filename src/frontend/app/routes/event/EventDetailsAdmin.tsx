import type { Route } from "./+types/EventDetailsAdmin"

import React from 'react';
import { Link } from "react-router";

import { getApiEventId } from '@hookgen/event/event';
import { type EventId } from "@hookgen/model";
import { EventDetailsAdminComponent } from "@routes/event/EventComponents";

export async function loader({ params }: Route.LoaderArgs) {
    const id_event_number = Number(params.id_event) as EventId;
    const event_data = await getApiEventId(id_event_number);

    return {
        id_event:id_event_number,
        event_data,
    };
}


export default function EventDetailsAdmin({
    loaderData,
}: Route.ComponentProps) {

    const id_event = loaderData.id_event;
    const event = loaderData.event_data;

    return <EventDetailsAdminComponent event={event} id_event={id_event} />

}
