import type { Route } from './+types/Pairings';
import React from 'react';

import {
    useGetApiPhaseIdHeats,
} from "@hookgen/heat/heat";
import { useGetApiCompIdBibs } from '@hookgen/bib/bib';
import { PairingListComponent } from '~/routes/phase/PairingComponents';


import {
    combineClientLoader, combineServerLoader, bibsListLoader,
    competitionLoader, eventLoader, heatListLoader, queryClient,
    phaseLoader,
    judgePanelLoader,
    phaseListLoader,
} from '~/queryClient';
import { useGetApiPhaseIdJudges } from '~/hookgen/judge/judge';
import { useQueries } from '@tanstack/react-query';
import { getGetApiPhaseIdQueryOptions } from '~/hookgen/phase/phase';
import { RoundItem, type Phase } from '~/hookgen/model';


const loader_array = [eventLoader, competitionLoader, phaseListLoader,
    bibsListLoader, phaseLoader, heatListLoader, judgePanelLoader];

const roundOrder: Record<RoundItem, number> = {
    [RoundItem.Prelims]: 0,
    [RoundItem.Octofinals]: 1,
    [RoundItem.Quarterfinals]: 2,
    [RoundItem.Semifinals]: 3,
    [RoundItem.Finals]: 4
}

export async function loader({ params }: Route.LoaderArgs) {

    const combinedData = await combineServerLoader(loader_array, params);

    return combinedData;
}

let isInitialRequest = true;

export async function clientLoader({
    params,
    serverLoader,
}: Route.ClientLoaderArgs) {

    if (isInitialRequest) {
        isInitialRequest = false;
        const serverData = await serverLoader();

        loader_array.forEach((l) => l.cache(queryClient, serverData));

        return serverData;
    }

    const combinedData = await combineClientLoader(loader_array, params);
    return combinedData;
}
clientLoader.hydrate = true;


export default function HeatsList({ loaderData }: Route.ComponentProps) {

    const { data: heats, isSuccess: isSuccessHeats } = useGetApiPhaseIdHeats(loaderData.id_phase, {
        query: {
            initialData: loaderData.heat_list
        }
    });

    const { data: dataBibs, isSuccess: isSuccessBibs } = useGetApiCompIdBibs(loaderData.id_competition, {
        query: {
            initialData: loaderData.bibs_list
        }
    });

    const { data: panel_data, isSuccess: isSuccessPanel } = useGetApiPhaseIdJudges(loaderData.id_phase, {
        query: {
            initialData: loaderData.panel_data
        }
    });

    const phase_list = loaderData.phase_list;

    const phaseDataQueries = useQueries({
        queries: phase_list.phases.map((id_phase) => ({
            ...getGetApiPhaseIdQueryOptions(id_phase),
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
            return { ...p, id_phase: phase_list.phases[index] };
        })
        .sort((a, b) => roundOrder[a.round[0]] - roundOrder[b.round[0]]).map((p) => p.id_phase).filter(
            (_, index, arr) => index < arr.findIndex((id_p) => loaderData.id_phase === id_p)
        )
        .at(-1);

    return (
        <>
            <p>Current phase {loaderData.id_phase}; all phases : {phase_list.phases.join(",")}</p>
            <PairingListComponent panel_data={panel_data}
                id_phase={loaderData.id_phase}
                heats={heats}
                dataBibs={dataBibs} />
        </>
    );

}

export const handle = {
    breadcrumb: () => "Pairings"
};
