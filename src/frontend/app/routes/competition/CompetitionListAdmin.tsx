import type { Route } from "./+types/CompetitionListAdmin"

import React from 'react';

import { EventCompetitionListComponent } from "@routes/competition/CompetitionComponents";

import { getGetApiEventIdCompsQueryOptions } from "~/hookgen/event/event";
import type { EventId } from "~/hookgen/model";
import { dehydrate, QueryClient } from "@tanstack/react-query";
import { getGetApiCompIdQueryOptions } from "~/hookgen/competition/competition";

export async function loader({ params }: Route.LoaderArgs) {

    const queryClient = new QueryClient();

    const id_event = Number(params.id_event) as EventId;
    const competition_list = await queryClient.fetchQuery(getGetApiEventIdCompsQueryOptions(id_event))
    await Promise.all(
        competition_list.competitions.map((id_competition) =>
            queryClient.prefetchQuery(getGetApiCompIdQueryOptions(id_competition)))
    );

    return { dehydratedState: dehydrate(queryClient) };
}


export default function CompetitionList({
    params
}: Route.ComponentProps) {

    const id_event = Number(params.id_event) as EventId;

    return (
        <>
            <EventCompetitionListComponent id_event={id_event} />
        </>
    );
}
