
import type { Route } from './+types/BibListEventAdmin';
import React from 'react';

import {
    type EventId,
} from "@hookgen/model";
import { BibListEventAdminComponent } from '@routes/bib/BibComponents';
import { getGetApiCompIdBibsQueryOptions, } from '@hookgen/bib/bib';
import { dehydrate, QueryClient } from '@tanstack/react-query';
import { getGetApiCompIdQueryOptions } from '~/hookgen/competition/competition';
import { getGetApiEventIdCompsQueryOptions, getGetApiEventIdQueryOptions } from '~/hookgen/event/event';


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


export default function BibListEventAdminRoute({ params }: Route.ComponentProps) {

    const id_event = Number(params.id_event) as EventId;

    return (
        <>
            <BibListEventAdminComponent id_event={id_event} />
        </>
    );
}