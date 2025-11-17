import type { Route } from './+types/JudgeForm';
import React, { useEffect } from 'react';

import type { Panel, PhaseId, } from "@hookgen/model";
import { useParams } from "react-router";
import { useGetApiPhaseIdJudges, } from '@hookgen/judge/judge';
import { JudgeFormComponent } from '@routes/judge/JudgeComponents';
import {
    combineClientLoader, combineServerLoader, competitionListLoader, competitionLoader,
    eventLoader, queryClient, phaseLoader, judgePanelLoader,
} from '~/queryClient';


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



export default function JudgeForm({loaderData}: Route.ComponentProps) {

    const id_phase = loaderData.id_phase;

    const { data, isLoading, } = useGetApiPhaseIdJudges(id_phase, {
        query: {
            initialData: loaderData.panel_data
        }
    });


    if (isLoading) return <div>Chargement...</div>;

    const judgePanel: Panel = data ?? { panel_type: "couple", couples: { dancers: [] } };

    return (
        <>
            <JudgeFormComponent
                id_phase={id_phase}
                panel={judgePanel}
            />
        </>
    );
}
