
import React from 'react';

import type { Route } from './+types/NewBibForm';
import { BibFormComponent, SelectNewBibFormComponent } from '@routes/bib/NewBibFormComponent';
import { getGetApiDancersQueryOptions, useGetApiDancers } from '~/hookgen/dancer/dancer';

import {
    type BibList, type CompetitionId, type EventId,
} from "@hookgen/model";
import { getGetApiCompIdQueryOptions } from '@hookgen/competition/competition';
import { getGetApiEventIdQueryOptions } from '@hookgen/event/event';
import { getGetApiCompIdBibsQueryOptions, useGetApiCompIdBibs } from '@hookgen/bib/bib';
import { dehydrate, QueryClient } from '@tanstack/react-query';

export async function loader({ params }: Route.LoaderArgs) {

    const queryClient = new QueryClient();
    const id_event = Number(params.id_event) as EventId;
    await queryClient.prefetchQuery(getGetApiEventIdQueryOptions(id_event));
    const id_competition = Number(params.id_competition) as CompetitionId;
    await queryClient.prefetchQuery(getGetApiCompIdQueryOptions(id_competition));
    await queryClient.prefetchQuery(getGetApiCompIdBibsQueryOptions(id_competition));
    await queryClient.prefetchQuery(getGetApiDancersQueryOptions());

    return { dehydratedState: dehydrate(queryClient) };
}


export default function BibHomePublic({ params }: Route.ComponentProps) {


    const id_competition = Number(params.id_competition) as CompetitionId;

    return (
        <>
            <BibFormComponent id_competition={id_competition} />
        </>
    );
}

export const handle = {
    breadcrumb: () => "New"
};
