import type { Route } from './+types/JudgeForm';

import type { PhaseId, CompetitionId, EventId } from "@hookgen/model";
import { useParams } from "react-router";
import { getGetApiPhaseIdJudgesQueryOptions } from '@hookgen/judge/judge';
import { JudgeFormComponent } from '@routes/judge/JudgeComponents';

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


export default function JudgeForm({params}: Route.ComponentProps) {

    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;
    const id_phase = Number(params.id_phase) as PhaseId;

    return (
        <>
            <JudgeFormComponent id_phase={id_phase} />
        </>
    );
}
