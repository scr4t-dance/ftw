import type { Route } from "./+types/PhaseList";
import React from 'react';

import { PhaseListComponent } from "@routes/phase/PhaseComponents";
import { getGetApiCompIdPhasesQueryOptions, useGetApiCompIdPhases } from "~/hookgen/phase/phase";

import { getGetApiEventIdCompsQueryOptions, getGetApiEventIdQueryOptions } from '@hookgen/event/event';
import { getGetApiCompIdQueryOptions } from '@hookgen/competition/competition';
import { dehydrate, QueryClient } from "@tanstack/react-query";
import type { CompetitionId, EventId, PhaseId } from "~/hookgen/model";

export async function loader({ params }: Route.LoaderArgs) {

    const queryClient = new QueryClient();
    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;

    await queryClient.prefetchQuery(getGetApiEventIdQueryOptions(id_event));
    await queryClient.prefetchQuery(getGetApiEventIdCompsQueryOptions(id_event));
    await queryClient.prefetchQuery(getGetApiCompIdQueryOptions(id_competition));
    await queryClient.prefetchQuery(getGetApiCompIdPhasesQueryOptions(id_competition));

    return { dehydratedState: dehydrate(queryClient) };
}


export default function PhaseList({ params }: Route.ComponentProps) {

    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;

    const { data: phase_list } = useGetApiCompIdPhases(id_competition);

    return (<PhaseListComponent
        id_competition={id_competition}
    />);

}
