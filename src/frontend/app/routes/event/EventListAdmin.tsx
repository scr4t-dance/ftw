import type { Route } from "./+types/EventListAdmin";

import React from 'react';
import { type EventIdList, type Event } from "@hookgen/model";

import { getApiEventId, getApiEvents } from "~/hookgen/event/event";
import { EventListComponent } from "./EventComponents";
import { Link } from "react-router";


export async function loader({ }: Route.LoaderArgs) {
    const event_list = await getApiEvents();
    const event_data = await Promise.all(
        event_list.events.map((id_event) => getApiEventId(id_event))
    );

    return {
        event_list,
        event_data,
    };
}


export default function EventList({
    loaderData,
}: Route.ComponentProps) {

    const event_list: EventIdList = loaderData.event_list;
    const event_data: Event[] = loaderData.event_data;

    return (
        <>
            <Link to={`new`}>
                Créer un nouvel événement
            </Link>

            <EventListComponent event_list={event_list} event_data={event_data} />
        </>
    );

}
