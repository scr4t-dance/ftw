import type { Route } from './+types/Pairings';
import React from 'react';

import { getGetApiPhaseIdJudgesQueryOptions } from '~/hookgen/judge/judge';
import { dehydrate, QueryClient } from '@tanstack/react-query';
import type { CompetitionId, EventId, PhaseId } from '~/hookgen/model';
import { getGetApiEventIdQueryOptions } from '@hookgen/event/event';
import { getGetApiCompIdQueryOptions } from '@hookgen/competition/competition';
import { getGetApiPhaseIdHeatsQueryOptions } from "@hookgen/heat/heat";
import { getGetApiCompIdBibsQueryOptions } from '@hookgen/bib/bib';
import { getGetApiPhaseIdQueryOptions } from '~/hookgen/phase/phase';
import { PreviousPhasePairingComponent } from './PairingComponents';

export async function loader({ params }: Route.LoaderArgs) {

    const queryClient = new QueryClient();
    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;
    const id_phase = Number(params.id_phase) as PhaseId;

    await queryClient.prefetchQuery(getGetApiEventIdQueryOptions(id_event));
    await queryClient.prefetchQuery(getGetApiCompIdQueryOptions(id_competition));
    await queryClient.prefetchQuery(getGetApiCompIdBibsQueryOptions(id_competition));

    await queryClient.prefetchQuery(getGetApiPhaseIdQueryOptions(id_phase));
    await queryClient.prefetchQuery(getGetApiPhaseIdHeatsQueryOptions(id_phase));
    await queryClient.prefetchQuery(getGetApiPhaseIdJudgesQueryOptions(id_phase));

    return { dehydratedState: dehydrate(queryClient) };
}



export default function Pairings({ params }: Route.ComponentProps) {


    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;
    const id_phase = Number(params.id_phase) as PhaseId;

    return (
        <>
            <PreviousPhasePairingComponent id_competition={id_competition} id_phase={id_phase}  />
        </>
    );

}

export const handle = {
    breadcrumb: () => "Pairings"
};
