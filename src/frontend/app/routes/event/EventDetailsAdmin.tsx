import type { Route } from "./+types/EventDetailsAdmin"

import React from 'react';
import { Link } from "react-router";

import { EventDetailsAdminComponent } from "@routes/event/EventComponents";
import { combineClientLoader, combineServerLoader, competitionListLoader, eventLoader, queryClient } from "~/queryClient";
import { getApiCompId, getGetApiCompIdQueryKey, getGetApiCompIdQueryOptions } from "~/hookgen/competition/competition";
import { useGetApiEventIdComps } from "~/hookgen/event/event";
import { useQueries } from "@tanstack/react-query";
import type { Competition, CompetitionIdList } from "~/hookgen/model";
import { getGetApiCompIdBibsQueryKey } from "~/hookgen/bib/bib";


const loader_array = [eventLoader, competitionListLoader,];


export async function loader({ params }: Route.LoaderArgs) {

    const combinedData = await combineServerLoader(loader_array, params);
    const competition_data_list = await Promise.all(
        combinedData.competition_list.competitions.map((id_competition) => getApiCompId(id_competition))
    );

    return {
        ...combinedData,
        competition_data_list,
    };
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
        (serverData.competition_list as CompetitionIdList).competitions.forEach((id_competition, index) => (
            queryClient.setQueryData(getGetApiCompIdQueryKey(id_competition), serverData.competition_data_list[index])
        ));


        return serverData;
    }

    const combinedData = await combineClientLoader(loader_array, params);
    const competition_data_list = await Promise.all(
        combinedData.competition_list.competitions.map((id_competition) => getApiCompId(id_competition))
    );

    return {
        ...combinedData,
        competition_data_list,
    };
}
clientLoader.hydrate = true;

export default function EventDetailsAdmin({
    loaderData,
}: Route.ComponentProps) {

    const id_event = loaderData.id_event;
    const event = loaderData.event_data;

    const { data: competition_list } = useGetApiEventIdComps(id_event, {
        query: {
            initialData: loaderData.competition_list
        }
    });

    const competitionDetailsQueries = useQueries({
        queries: competition_list.competitions.map((id_competition) => (
            getGetApiCompIdQueryOptions(id_competition)
        ))
    });

    const competition_data_list = competitionDetailsQueries.map((q) => q.data as Competition);

    return <EventDetailsAdminComponent
        event={event} id_event={id_event}
        competition_id_list={competition_list}
        competition_data_list={competition_data_list}
    />

}
