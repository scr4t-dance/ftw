
import type { Route } from './+types/BibListAdmin';
import React from 'react';
import { Link, useLocation } from "react-router";

import {
    type BibList, type CompetitionId, type EventId,
} from "@hookgen/model";
import { getGetApiCompIdQueryOptions } from '@hookgen/competition/competition';
import { getGetApiEventIdQueryOptions } from '@hookgen/event/event';
import { BibListComponent } from '@routes/bib/BibComponents';
import { getGetApiCompIdBibsQueryOptions, useGetApiCompIdBibs } from '@hookgen/bib/bib';
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

    const location = useLocation();
    const url = location.pathname.includes("bibs") ? "" : "bibs/"

    const { data: bibs_list, isLoading } = useGetApiCompIdBibs(id_competition);

    if (isLoading) return <div>Loading...</div>

    if (!bibs_list) return <div>Pas de dossards pour la compétition {id_competition}</div>

    return (
        <>
            <Link to={`${url}new`}>
                Créer un-e nouvel-le compétiteur-euse
            </Link>
            <BibListComponent id_competition={id_competition} />
        </>
    );
}

export default BibList;