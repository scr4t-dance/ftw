import type { Route } from './+types/Pairings';
import React from 'react';

import {
    useGetApiPhaseIdHeats,
} from "@hookgen/heat/heat";
import { getGetApiCompIdBibsQueryOptions, useGetApiCompIdBibs } from '@hookgen/bib/bib';
import { PairingListComponent } from '~/routes/phase/PairingComponents';
import { getGetApiPhaseIdJudgesQueryOptions, useGetApiPhaseIdJudges } from '~/hookgen/judge/judge';
import { dehydrate, QueryClient, useQueries } from '@tanstack/react-query';
import { getGetApiCompIdPhasesQueryOptions, getGetApiPhaseIdQueryOptions, useGetApiCompIdPhases } from '~/hookgen/phase/phase';
import { RoundItem, type CompetitionId, type EventId, type Phase, type PhaseId, type PhaseIdList } from '~/hookgen/model';
import { getGetApiEventIdQueryOptions } from '~/hookgen/event/event';
import { getGetApiCompIdQueryOptions } from '~/hookgen/competition/competition';

const roundOrder: Record<RoundItem, number> = {
    [RoundItem.Prelims]: 0,
    [RoundItem.Octofinals]: 1,
    [RoundItem.Quarterfinals]: 2,
    [RoundItem.Semifinals]: 3,
    [RoundItem.Finals]: 4
}

export async function loader({ params }: Route.LoaderArgs) {
    const queryClient = new QueryClient();
    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;
    const id_phase = Number(params.id_phase) as PhaseId;

    await queryClient.prefetchQuery(getGetApiEventIdQueryOptions(id_event));
    await queryClient.prefetchQuery(getGetApiCompIdQueryOptions(id_competition));
    await queryClient.prefetchQuery(getGetApiCompIdBibsQueryOptions(id_competition));
    await queryClient.prefetchQuery(getGetApiCompIdPhasesQueryOptions(id_competition));

    await queryClient.prefetchQuery(getGetApiPhaseIdQueryOptions(id_phase));
    await queryClient.prefetchQuery(getGetApiPhaseIdJudgesQueryOptions(id_phase));

    return { dehydratedState: dehydrate(queryClient) };
}

export default function HeatsList({ params }: Route.ComponentProps) {

    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;
    const id_phase = Number(params.id_phase) as PhaseId;

    const { data: heats, isSuccess: isSuccessHeats } = useGetApiPhaseIdHeats(id_phase);
    const { data: dataBibs, isSuccess: isSuccessBibs } = useGetApiCompIdBibs(id_competition);
    const { data: phase_list, isSuccess: isSuccessPhaseList } = useGetApiCompIdPhases(id_competition);
    const { data: panel_data, isSuccess: isSuccessPanel } = useGetApiPhaseIdJudges(id_phase);


    const phaseDataQueries = useQueries({
        queries: (phase_list as PhaseIdList).phases.map((id_phase) => ({
            ...getGetApiPhaseIdQueryOptions(id_phase),
            enabled: isSuccessPhaseList
        })),
    });

    const isPhasesLoading = phaseDataQueries.some((query) => query.isLoading);
    const isPhasesError = phaseDataQueries.some((query) => query.isError);


    if (isPhasesLoading) return <div>Loading judges details...</div>;
    if (isPhasesError) return (
        <div>
            Error loading phases data
            {
                phaseDataQueries.map((query) => {
                    return (<p>{query.error?.message}</p>);
                })
            }
        </div>);
    if (!isSuccessBibs) return <div>Chargement des bibs...</div>;
    if (!isSuccessHeats) return <div>Chargement des heats...</div>;
    if (!isSuccessPanel) return <div>Chargement de la phase...</div>;

    const phase_data_list = phaseDataQueries.map((q) => q.data as Phase);
    const previous_id_phase = phase_data_list
        .map((p, index) => {
            return { ...p, id_phase: (phase_list as PhaseIdList).phases[index] };
        })
        .sort((a, b) => roundOrder[a.round[0]] - roundOrder[b.round[0]]).map((p) => p.id_phase).filter(
            (_, index, arr) => index < arr.findIndex((id_p) => id_phase === id_p)
        )
        .at(-1);

    return (
        <>
            <p>Current phase {id_phase}; all phases : {(phase_list as PhaseIdList).phases.join(",")}</p>
            <PairingListComponent panel_data={panel_data}
                id_phase={id_phase}
                heats={heats}
                dataBibs={dataBibs} />
        </>
    );

}

export const handle = {
    breadcrumb: () => "Pairings"
};
