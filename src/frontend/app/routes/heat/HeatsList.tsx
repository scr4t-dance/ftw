import type { Route } from './+types/HeatsList';
import React from 'react';

import type { CompetitionId, PhaseId, } from "@hookgen/model";
import { useParams } from "react-router";
import { useGetApiPhaseId } from "@hookgen/phase/phase";
import {
    useGetApiPhaseIdHeats,
} from "@hookgen/heat/heat";
import { useGetApiCompIdBibs } from '@hookgen/bib/bib';
import { HeatsListComponent } from './HeatComponents';


import {
    combineClientLoader, combineServerLoader, bibsListLoader,
    competitionLoader, eventLoader, phaseListLoader, heatListLoader, queryClient,
} from '~/queryClient';


const loader_array = [eventLoader, competitionLoader, bibsListLoader, phaseListLoader, heatListLoader];


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

    if (!isSuccessBibs) return <div>Chargement des bibs...</div>;
    if (!isSuccessHeats) return <div>Chargement des heats...</div>;

    return <HeatsListComponent id_phase={loaderData.id_phase} heats={heats} dataBibs={dataBibs} />

}

export const handle = {
    breadcrumb: () => "Heats"
};
