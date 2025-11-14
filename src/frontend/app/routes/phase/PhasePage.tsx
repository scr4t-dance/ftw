import type { Route } from './+types/PhasePage';
import React from 'react';


import { PhasePage, PhasePageComponent } from '@routes/phase/PhaseComponents';

import { dehydrate, QueryClient } from '@tanstack/react-query';
import { getGetApiEventIdQueryOptions } from '@hookgen/event/event';
import { getGetApiCompIdQueryOptions } from '@hookgen/competition/competition';
import { getGetApiPhaseIdQueryOptions } from '@hookgen/phase/phase';
import type { CompetitionId, EventId, PhaseId } from '~/hookgen/model';

export async function loader({ params }: Route.LoaderArgs) {

    const queryClient = new QueryClient();
    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;
    const id_phase = Number(params.id_phase) as PhaseId;

    await queryClient.prefetchQuery(getGetApiEventIdQueryOptions(id_event));
    await queryClient.prefetchQuery(getGetApiCompIdQueryOptions(id_competition));

    await queryClient.prefetchQuery(getGetApiPhaseIdQueryOptions(id_phase));

    return { dehydratedState: dehydrate(queryClient) };
}




export default function PhasePageRoute({params}: Route.ComponentProps) {

    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;
    const id_phase = Number(params.id_phase) as PhaseId;
    return (<PhasePageComponent id_phase={id_phase} id_competition={id_competition} />);
}
