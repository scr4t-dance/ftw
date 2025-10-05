import type { Route } from './+types/JudgeList';
import React from 'react';
import { useParams } from "react-router";

import {
    type PhaseId,
} from "@hookgen/model";

import { JudgeListComponent } from './JudgeComponents';
import {
    combineClientLoader, combineServerLoader, competitionListLoader, competitionLoader,
    eventLoader, queryClient, phaseLoader, judgePanelLoader,
} from '~/queryClient';
import { useGetApiPhaseIdJudges } from '~/hookgen/judge/judge';



const loader_array = [eventLoader, competitionLoader, competitionListLoader,phaseLoader, judgePanelLoader];


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


export default function JudgeList({loaderData}: Route.ComponentProps) {

    const {data: panel_data, isLoading} = useGetApiPhaseIdJudges(loaderData.id_phase, {
        query: {
            initialData: loaderData.panel_data
        }
    })

    if(isLoading) return <div>Chargement panel de juge</div>

    return (
        <>
            <JudgeListComponent panel_data={panel_data} />
        </>
    );
};
