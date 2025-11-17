
import type { Route } from './+types/BibListEventAdmin';
import React from 'react';

import {
    type Competition,
    type CompetitionIdList,
} from "@hookgen/model";
import { BibListEventAdminComponent } from '@routes/bib/BibComponents';
import { getApiCompIdBibs, getGetApiCompIdBibsQueryKey, getGetApiCompIdBibsQueryOptions, } from '@hookgen/bib/bib';
import { combineClientLoader, combineServerLoader, competitionListLoader, eventLoader, queryClient } from '~/queryClient';
import { useQueries } from '@tanstack/react-query';
import { getApiCompId, getGetApiCompIdQueryKey, getGetApiCompIdQueryOptions } from '~/hookgen/competition/competition';


const loader_array = [eventLoader, competitionListLoader,];


export async function loader({ params }: Route.LoaderArgs) {

    const combinedData = await combineServerLoader(loader_array, params);
    const competition_data_list = await Promise.all(
        combinedData.competition_list.competitions.map((id_competition) => getApiCompId(id_competition))
    );
    const bibs_list_array = await Promise.all(
        combinedData.competition_list.competitions.map((id_competition) => getApiCompIdBibs(id_competition))
    );

    return {
        ...combinedData,
        competition_data_list,
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

        loader_array.forEach((l) => l.cache(queryClient, serverData));
        (serverData.competition_list as CompetitionIdList).competitions.forEach((id_competition, index) => (
            queryClient.setQueryData(getGetApiCompIdQueryKey(id_competition), serverData.competition_data_list[index])
        ));
        (serverData.competition_list as CompetitionIdList).competitions.forEach((id_competition, index) => (
            queryClient.setQueryData(getGetApiCompIdBibsQueryKey(id_competition), serverData.bibs_list_array[index])
        ));

        return serverData;
    }

    const combinedData = await combineClientLoader(loader_array, params);
    const competition_data_list = await Promise.all(
        combinedData.competition_list.competitions.map((id_competition) => getApiCompId(id_competition))
    );
    const bibs_list_array = await Promise.all(
        combinedData.competition_list.competitions.map((id_competition) => getApiCompIdBibs(id_competition))
    );

    return {
        ...combinedData,
        competition_data_list,
        bibs_list_array,
    };
}
clientLoader.hydrate = true;



function BibListEventAdmin({
    loaderData
}: Route.ComponentProps) {


    const competitionDetailsQueries = useQueries({
        queries: loaderData.competition_list.competitions.map((id_competition, index) => ({
            ...getGetApiCompIdQueryOptions(id_competition, {
                query: { initialData: loaderData.competition_data_list[index] }
            }),
        })),
    });

    const bibsQueries = useQueries({
        queries: loaderData.competition_list.competitions.map((id_competition, index) => ({
            ...getGetApiCompIdBibsQueryOptions(id_competition, {
                query: { initialData: loaderData.bibs_list_array[index] }
            }),
        })),
    });

    const competition_data_list = competitionDetailsQueries.map((q) => q.data as Competition)
    const bibs_list_array = bibsQueries.map((q) => q.data ?? { bibs: [] });

    return (
        <>
            <BibListEventAdminComponent competition_list={loaderData.competition_list} competition_data_list={competition_data_list} bibs_list_array={bibs_list_array} />
        </>
    );
}

export default BibListEventAdmin;