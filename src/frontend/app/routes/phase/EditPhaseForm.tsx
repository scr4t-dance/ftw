import type { Route } from './+types/EditPhaseForm';
import React, { useEffect } from 'react';
// import { useNavigate } from "react-router";

import { dehydrate, QueryClient } from '@tanstack/react-query';

import type {
    CompetitionId,
    EventId,
    PhaseId
} from '@hookgen/model';
import { EditPhaseFormComponent } from '@routes/phase/ArtefactFormElement';
import { getGetApiEventIdCompsQueryOptions } from '@hookgen/event/event';

import { getGetApiEventIdQueryOptions } from '@hookgen/event/event';
import { getGetApiCompIdQueryOptions } from '@hookgen/competition/competition';
import { getGetApiPhaseIdQueryOptions } from '@hookgen/phase/phase';

export async function loader({ params }: Route.LoaderArgs) {

    const queryClient = new QueryClient();
    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;
    const id_phase = Number(params.id_phase) as PhaseId;

    await queryClient.prefetchQuery(getGetApiEventIdQueryOptions(id_event));
    await queryClient.prefetchQuery(getGetApiEventIdCompsQueryOptions(id_event));
    await queryClient.prefetchQuery(getGetApiCompIdQueryOptions(id_competition));
    await queryClient.prefetchQuery(getGetApiPhaseIdQueryOptions(id_phase));

    return { dehydratedState: dehydrate(queryClient) };
}


export default function EditPhaseFormRoute({
    params
}: Route.ComponentProps) {

    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;
    const id_phase = Number(params.id_phase) as PhaseId;

    return <EditPhaseFormComponent id_phase={id_phase} />

}
