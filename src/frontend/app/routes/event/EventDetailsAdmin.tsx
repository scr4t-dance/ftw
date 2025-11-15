import type { Route } from "./+types/EventDetailsAdmin"

import React from 'react';

import { EventDetailsAdminComponent } from "@routes/event/EventComponents";
import { getGetApiCompIdQueryOptions } from "~/hookgen/competition/competition";
import type { EventId } from "~/hookgen/model";
import { dehydrate, QueryClient } from "@tanstack/react-query";
import { getGetApiEventIdCompsQueryOptions } from "~/hookgen/event/event";

export async function loader({ params }: Route.LoaderArgs) {

    const queryClient = new QueryClient();

    const id_event = Number(params.id_event) as EventId;

    const competition_list = await queryClient.fetchQuery(getGetApiEventIdCompsQueryOptions(id_event))

    await Promise.all(
        competition_list.competitions.map((id_competition) => queryClient.prefetchQuery(getGetApiCompIdQueryOptions(id_competition)))
    );

    return { dehydratedState: dehydrate(queryClient) };
}

export default function EventDetailsAdmin({
    params,
}: Route.ComponentProps) {

    const id_event = Number(params.id_event) as EventId;

    return <EventDetailsAdminComponent id_event={id_event} />

}
