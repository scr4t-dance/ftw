import type { Route } from './+types/PhasePage';
import React from 'react';

import {
    combineClientLoader, combineServerLoader, competitionListLoader,
    competitionLoader, eventLoader, phaseLoader, queryClient,
} from '~/queryClient';
import { PhasePage } from '@routes/phase/PhaseComponents';




const loader_array = [eventLoader, competitionLoader, competitionListLoader, phaseLoader];


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



export default function PhasePageRoute({
    loaderData
}: Route.ComponentProps) {

    return (<PhasePage phase_data={loaderData.phase_data} competition_data={loaderData.competition_data} />);
}
