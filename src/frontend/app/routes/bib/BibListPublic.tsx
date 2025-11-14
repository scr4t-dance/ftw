
import React from 'react';
import { Link } from "react-router";
import {
    type BibList, type CompetitionId, type EventId,
} from "@hookgen/model";

import { getApiCompIdBibs, getGetApiCompIdBibsQueryOptions } from "@hookgen/bib/bib";

import type { Route } from './+types/BibListPublic';
import { getApiCompId, getGetApiCompIdQueryOptions } from '@hookgen/competition/competition';
import { getApiEventId, getGetApiEventIdQueryOptions } from '@hookgen/event/event';
import { PublicBibList, PublicBibListComponent } from '@routes/bib/BibComponents';
import { dehydrate, QueryClient } from '@tanstack/react-query';


const dancerLink = "dancers/"


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
            <Link to={`/${dancerLink}new`}>
                Créer un-e nouvel-le compétiteur-euse
            </Link>
            <PublicBibListComponent id_competition={id_competition} />
        </>
    );
}

export default BibList;