import type { Route } from "./+types/PhaseList";
import React from 'react';

import {
    combineClientLoader, combineServerLoader, competitionListLoader,
    competitionLoader, eventLoader, phaseListLoader, queryClient,
} from '~/queryClient';
import { PhaseListComponent } from "@routes/phase/PhaseComponents";
import { useGetApiCompIdPhases } from "~/hookgen/phase/phase";



const loader_array = [eventLoader, competitionLoader, competitionListLoader, phaseListLoader];


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



function PhaseList({ loaderData }: Route.ComponentProps) {

    const {data: phase_list} = useGetApiCompIdPhases(loaderData.id_competition, {
        query:{
            initialData: loaderData.phase_list,
        }
    });

    return (<PhaseListComponent
        id_competition={loaderData.id_competition}
        competition_data={loaderData.competition_data}
        phase_list={phase_list}
         />);

}

export default PhaseList;