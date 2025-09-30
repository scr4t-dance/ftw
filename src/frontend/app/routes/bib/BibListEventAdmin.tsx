
import type { Route } from './+types/BibListEventAdmin';
import React from 'react';
import { Link, useLocation } from "react-router";

import {
    type BibList, type CompetitionId, type CompetitionIdList, type EventId,
} from "@hookgen/model";
import { getApiEventId, getApiEventIdComps, getGetApiEventIdCompsQueryKey, getGetApiEventIdCompsQueryOptions, getGetApiEventIdQueryKey, getGetApiEventIdQueryOptions } from '@hookgen/event/event';
import { BareBibListComponent, BibListEventAdminComponent } from '@routes/bib/BibComponents';
import { getApiCompIdBibs, getGetApiCompIdBibsQueryKey, getGetApiCompIdBibsQueryOptions, useGetApiCompIdBibs } from '@hookgen/bib/bib';
import { queryClient } from '~/queryClient';
import { useQueries } from '@tanstack/react-query';

export async function loader({ params }: Route.LoaderArgs) {

    const id_event = Number(params.id_event) as EventId;
    const event_data = await getApiEventId(id_event);
    const competition_list = await getApiEventIdComps(id_event);
    const bibs_list_array = await Promise.all(
        competition_list.competitions.map((id_competition) => getApiCompIdBibs(id_competition))
    );
    return {
        id_event,
        event_data,
        competition_list,
        bibs_list_array,
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

        queryClient.setQueryData(getGetApiEventIdQueryKey(serverData.id_event), serverData.event_data);
        queryClient.setQueryData(getGetApiEventIdCompsQueryKey(serverData.id_event), serverData.competition_list);
        (serverData.competition_list as CompetitionIdList).competitions.forEach((id_competition, index) => (
            queryClient.setQueryData(getGetApiCompIdBibsQueryKey(id_competition), serverData.bibs_list_array[index])
        ));

        return serverData;
    }

    const id_event = Number(params.id_event) as EventId;
    const event_data = await queryClient.ensureQueryData(getGetApiEventIdQueryOptions(id_event));

    const competition_list = await queryClient.ensureQueryData(getGetApiEventIdCompsQueryOptions(id_event));
    const bibs_list_array = await Promise.all(
        competition_list.competitions.map((id_competition) => queryClient.ensureQueryData(getGetApiCompIdBibsQueryOptions(id_competition)))
    );

    return {
        id_event,
        event_data,
        competition_list,
        bibs_list_array,
    };
}
clientLoader.hydrate = true;



function BibListEventAdmin({
    loaderData
}: Route.ComponentProps) {

    const bibsQueries = useQueries({
        queries: loaderData.competition_list.competitions.map((id_competition, index) => ({
            ...getGetApiCompIdBibsQueryOptions(id_competition, {
                query: { initialData: loaderData.bibs_list_array[index] }
            }),
        })),
    });

    const bibs_list_array = bibsQueries.map((q) => q.data ?? {bibs:[]});

    return (
        <>
            <BibListEventAdminComponent competition_list={loaderData.competition_list} bibs_list_array={bibs_list_array} />
        </>
    );
}

export default BibListEventAdmin;