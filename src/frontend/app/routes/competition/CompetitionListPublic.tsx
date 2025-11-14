import type { Route } from "./+types/CompetitionListPublic"

import React from 'react';

import { type CompetitionIdList, type EventId } from "@hookgen/model";
import { CompetitionTableComponent } from "@routes/competition/CompetitionComponents";

import { useGetApiEventIdComps } from "~/hookgen/event/event";


import { EventCompetitionListComponent } from "@routes/competition/CompetitionComponents";

import { getGetApiEventIdCompsQueryOptions } from "~/hookgen/event/event";
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
