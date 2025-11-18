
import React from 'react';
import {
    type BibList, type CompetitionId, type EventId,
} from "@hookgen/model";

import { getGetApiCompIdBibsQueryOptions } from "@hookgen/bib/bib";

import type { Route } from './+types/BibListPublic';
import { getGetApiCompIdQueryOptions } from '@hookgen/competition/competition';
import { getGetApiEventIdQueryOptions } from '@hookgen/event/event';
import { PublicBibListComponent } from '@routes/bib/BibComponents';
import { dehydrate, QueryClient } from '@tanstack/react-query';

export async function loader({ params }: Route.LoaderArgs) {

    const queryClient = new QueryClient();
    const id_event = Number(params.id_event) as EventId;
    await queryClient.prefetchQuery(getGetApiEventIdQueryOptions(id_event));
    const id_competition = Number(params.id_competition) as CompetitionId;
    await queryClient.prefetchQuery(getGetApiCompIdQueryOptions(id_competition));
    await queryClient.prefetchQuery(getGetApiCompIdBibsQueryOptions(id_competition));

    return { dehydratedState: dehydrate(queryClient) };
}


function BibList({
    params
}: Route.ComponentProps) {

    const id_competition = Number(params.id_competition) as CompetitionId;

    return (
        <>
            <PublicBibListComponent id_competition={id_competition} />
        </>
    );
}

export default BibList;