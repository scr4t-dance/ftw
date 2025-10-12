import type { Route } from "./+types/CompetitionListPublic"

import React from 'react';

import { type CompetitionIdList, type EventId } from "@hookgen/model";
import { CompetitionTableComponent } from "@routes/competition/CompetitionComponents";

import {
    combineClientLoader, combineServerLoader, competitionListLoader, eventLoader,
    queryClient,
} from '~/queryClient';
import { useGetApiEventIdComps } from "~/hookgen/event/event";



const loader_array = [eventLoader, competitionListLoader];

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

export default function CompetitionList({
    params,
    loaderData
}: Route.ComponentProps) {

    const {data: competition_list} = useGetApiEventIdComps(loaderData.id_event, {
        query:{
            initialData:loaderData.competition_list
        }
    });

    return (
        <>
            <CompetitionTableComponent id_event={loaderData.id_event} competition_id_list={competition_list} />
        </>
    );
}
