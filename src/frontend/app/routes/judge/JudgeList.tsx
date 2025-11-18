import type { Route } from './+types/JudgeList';
import React from 'react';

import {
    type CompetitionId,
    type EventId,
    type PhaseId,
} from "@hookgen/model";

import { JudgeListComponent } from '@routes/judge/JudgeComponents';
import { getGetApiPhaseIdJudgesQueryOptions } from '~/hookgen/judge/judge';


import { dehydrate, QueryClient } from '@tanstack/react-query';
import { getGetApiEventIdQueryOptions } from '@hookgen/event/event';
import { getGetApiCompIdQueryOptions } from '@hookgen/competition/competition';
import { getGetApiPhaseIdQueryOptions } from '@hookgen/phase/phase';
import { getGetApiPhaseIdHeatsQueryOptions } from '@hookgen/heat/heat';

export async function loader({ params }: Route.LoaderArgs) {

    const queryClient = new QueryClient();
    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;
    const id_phase = Number(params.id_phase) as PhaseId;

    await queryClient.prefetchQuery(getGetApiEventIdQueryOptions(id_event));
    await queryClient.prefetchQuery(getGetApiCompIdQueryOptions(id_competition));

    await queryClient.prefetchQuery(getGetApiPhaseIdQueryOptions(id_phase));
    await queryClient.prefetchQuery(getGetApiPhaseIdHeatsQueryOptions(id_phase));
    await queryClient.prefetchQuery(getGetApiPhaseIdJudgesQueryOptions(id_phase));

    return { dehydratedState: dehydrate(queryClient) };
}


export default function JudgeList({params}: Route.ComponentProps) {

    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;
    const id_phase = Number(params.id_phase) as PhaseId;

    return (
        <>
            <JudgeListComponent id_phase={id_phase} />
        </>
    );
};
