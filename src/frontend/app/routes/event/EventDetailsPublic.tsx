import type { Route } from "./+types/EventDetailsPublic"

import React from 'react';

import { getGetApiEventIdQueryOptions, useGetApiEventId } from '@hookgen/event/event';
import { type EventId } from "@hookgen/model";
import { EventDetailsComponent } from "@routes/event/EventComponents";
import { dehydrate, QueryClient } from "@tanstack/react-query";

export async function loader({ params }: Route.LoaderArgs) {
    const id_event_number = Number(params.id_event) as EventId;

    const queryClient = new QueryClient();

    await queryClient.prefetchQuery(getGetApiEventIdQueryOptions(id_event_number));

    return { dehydratedState: dehydrate(queryClient) };
}


export default function EventDetails({
    params,
}: Route.ComponentProps) {

    const id_event = Number(params.id_event) as EventId;


    return <EventDetailsComponent id_event={id_event} />

}
