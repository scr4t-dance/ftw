
import type { Route } from './+types/BibListEventAdmin';
import React from 'react';

import {
    type Competition,
    type CompetitionIdList,
    type EventId,
} from "@hookgen/model";
import { BibListEventAdminComponent } from '@routes/bib/BibComponents';
import { getGetApiCompIdBibsQueryOptions, } from '@hookgen/bib/bib';
import { dehydrate, QueryClient, useQueries } from '@tanstack/react-query';
import { getGetApiCompIdQueryOptions } from '~/hookgen/competition/competition';
import { getGetApiEventIdCompsQueryOptions, getGetApiEventIdQueryOptions, useGetApiEventIdComps } from '~/hookgen/event/event';


export async function loader({ params }: Route.LoaderArgs) {

    const queryClient = new QueryClient();
    const id_event = Number(params.id_event) as EventId;
    await queryClient.prefetchQuery(getGetApiEventIdQueryOptions(id_event));
    const competition_list = await queryClient.fetchQuery(getGetApiEventIdCompsQueryOptions(id_event));
    await Promise.all(
        competition_list.competitions.map((id_competition) => queryClient.prefetchQuery(getGetApiCompIdQueryOptions(id_competition)))
    );
    await Promise.all(
        competition_list.competitions.map((id_competition) => queryClient.prefetchQuery(getGetApiCompIdBibsQueryOptions(id_competition)))
    )

    return { dehydratedState: dehydrate(queryClient) };
}


function BibListEventAdmin({ params }: Route.ComponentProps) {

    const id_event = Number(params.id_event) as EventId;
    const { data: competition_list, isSuccess } = useGetApiEventIdComps(id_event);

    const competitionDetailsQueries = useQueries({
        queries: (competition_list ?? { competitions: [] }).competitions.map((competitionId) => ({
            ...getGetApiCompIdQueryOptions(competitionId),
            enabled: !!competition_list,
        })),
    });

    const competitionBibsQueries = useQueries({
        queries: (competition_list ?? { competitions: [] }).competitions.map((competitionId) => ({
            ...getGetApiCompIdBibsQueryOptions(competitionId),
            enabled: !!competition_list,
        })),
    });


    const isDetailsLoading = competitionDetailsQueries.some((query) => query.isLoading);
    const isDetailsError = competitionDetailsQueries.some((query) => query.isError);
    const isBibsLoading = competitionBibsQueries.some((query) => query.isLoading);
    const isBibsError = competitionBibsQueries.some((query) => query.isError);


    if (!isSuccess) return <div>Loading competition details...</div>;
    if (isDetailsLoading) return <div>Loading competition details...</div>;
    if (isDetailsError) return (
        <div>
            Error loading competition details
            {
                competitionDetailsQueries.map((query) => {
                    return (<p>{query.error?.message}</p>);
                })
            }
        </div>);


    if (isBibsLoading) return <div>Loading competition details...</div>;
    if (isBibsError) return (
        <div>
            Error loading competition details
            {
                competitionBibsQueries.map((query) => {
                    return (<p>{query.error?.message}</p>);
                })
            }
        </div>);

    const competition_data_list = competitionDetailsQueries.map(q => q.data as Competition);

    const bibs_list_array = competitionBibsQueries.map((q) => q.data ?? { bibs: [] });

    return (
        <>
            <BibListEventAdminComponent competition_list={competition_list as CompetitionIdList} competition_data_list={competition_data_list} bibs_list_array={bibs_list_array} />
        </>
    );
}

export default BibListEventAdmin;