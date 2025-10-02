
import type { Route } from './+types/BibListAdmin';
import React from 'react';
import { Link, useLocation } from "react-router";

import {
    type BibList, type CompetitionId, type EventId,
} from "@hookgen/model";
import { getApiCompId, getGetApiCompIdQueryKey, getGetApiCompIdQueryOptions } from '@hookgen/competition/competition';
import { getApiEventId, getGetApiEventIdQueryKey, getGetApiEventIdQueryOptions } from '@hookgen/event/event';
import { BareBibListComponent } from '@routes/bib/BibComponents';
import { getApiCompIdBibs, getGetApiCompIdBibsQueryKey, getGetApiCompIdBibsQueryOptions, useGetApiCompIdBibs } from '@hookgen/bib/bib';
import { queryClient } from '~/queryClient';

export async function loader({ params }: Route.LoaderArgs) {

    const id_event = Number(params.id_event) as EventId;
    const event_data = await getApiEventId(id_event);
    const id_competition = Number(params.id_competition) as CompetitionId;
    const competition_data = await getApiCompId(id_competition);
    const bibs_list = await getApiCompIdBibs(id_competition);
    return {
        id_event,
        event_data,
        id_competition,
        competition_data,
        bibs_list,
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
        queryClient.setQueryData(getGetApiCompIdQueryKey(serverData.id_competition), serverData.competition_data);
        queryClient.setQueryData(getGetApiCompIdBibsQueryKey(serverData.id_competition), serverData.bibs_list);

        return serverData;
    }

    const id_event = Number(params.id_event) as EventId;
    const event_data = await queryClient.ensureQueryData(getGetApiEventIdQueryOptions(id_event));
    const id_competition = Number(params.id_competition) as CompetitionId;
    const competition_data = await queryClient.ensureQueryData(getGetApiCompIdQueryOptions(Number(params.id_competition)));
    const bibs_list = await queryClient.ensureQueryData(getGetApiCompIdBibsQueryOptions(Number(params.id_competition)));

    return {
        id_event,
        event_data,
        id_competition,
        competition_data,
        bibs_list,
    };
}
clientLoader.hydrate = true;


function BibList({
    loaderData
}: Route.ComponentProps) {

    const location = useLocation();
    const url = location.pathname.includes("bibs") ? "" : "bibs/"

    const { data: bibs_list } = useGetApiCompIdBibs(loaderData.id_competition, {
            query: {
                initialData: loaderData.bibs_list,
            }
        }
    );

    return (
        <>
            <Link to={`${url}new`}>
                Créer un-e nouvel-le compétiteur-euse
            </Link>
            <BareBibListComponent bib_list={bibs_list.bibs} />
        </>
    );
}

export default BibList;