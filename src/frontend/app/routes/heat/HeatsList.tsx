import type { Route } from './+types/HeatsList';
import React from 'react';

import {
    useGetApiPhaseIdHeats,
} from "@hookgen/heat/heat";
import { useGetApiCompIdBibs } from '@hookgen/bib/bib';
import { HeatsListComponent } from './HeatComponents';


import {
    combineClientLoader, combineServerLoader, bibsListLoader,
    competitionLoader, eventLoader, heatListLoader, queryClient,
    phaseLoader,
    judgePanelLoader,
} from '~/queryClient';
import { useGetApiPhaseIdJudges } from '~/hookgen/judge/judge';


const loader_array = [eventLoader, competitionLoader, bibsListLoader, phaseLoader, heatListLoader,judgePanelLoader];


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
            initialData:loaderData.bibs_list
        }
    });

    const { data: panel_data, isSuccess: isSuccessPanel } = useGetApiPhaseIdJudges(loaderData.id_phase, {
        query: {
            initialData:loaderData.panel_data
        }
    });

    if (!isSuccessBibs) return <div>Chargement des bibs...</div>;
    if (!isSuccessHeats) return <div>Chargement des heats...</div>;
    if (!isSuccessPanel) return <div>Chargement de la phase...</div>;

    return <HeatsListComponent id_phase={loaderData.id_phase} panel_data={panel_data} heats={heats} dataBibs={dataBibs} />

}

export const handle = {
    breadcrumb: () => "Heats"
};
