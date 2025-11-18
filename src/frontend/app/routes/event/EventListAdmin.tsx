import type { Route } from "./+types/EventListAdmin";

import React from 'react';
import { type EventIdList, type Event } from "@hookgen/model";

import { getGetApiEventIdQueryOptions, getGetApiEventsQueryOptions, useGetApiEvents } from "~/hookgen/event/event";
import { EventListComponent } from "./EventComponents";
import { dehydrate, QueryClient, useQueries } from "@tanstack/react-query";
import { Link } from "react-router";

export async function loader({ }: Route.LoaderArgs) {

    const queryClient = new QueryClient();

    const event_list = await queryClient.fetchQuery(getGetApiEventsQueryOptions());

    await Promise.all(
        event_list.events.map((id_event) => queryClient.prefetchQuery(getGetApiEventIdQueryOptions(id_event)))
    );

    return { dehydratedState: dehydrate(queryClient) };
}


export default function EventList({}: Route.ComponentProps) {

    const { data: event_list } = useGetApiEvents();

    const eventDataQueries = useQueries({
        queries: (event_list as EventIdList).events.map((id_event) => ({
            ...getGetApiEventIdQueryOptions(id_event),
            enabled: !!event_list?.events,
        }))
    });

    const event_data = eventDataQueries.map(q => q.data as Event);

    return (
        <>
            <Link to={`new`}>
                Créer un nouvel événement
            </Link>

            <EventListComponent event_list={event_list as EventIdList} event_data={event_data} />
        </>
    );
}