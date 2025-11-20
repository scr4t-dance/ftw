
import React from 'react';

import type { Route } from './+types/NewBibForm';
import { SelectNewBibFormComponent } from '@routes/bib/NewBibFormComponent';
import { useGetApiCompIdBibs } from '@hookgen/bib/bib';
import {
    bibsListLoader, combineClientLoader, combineServerLoader, competitionLoader,
    dancerListLoader, eventLoader, queryClient,
} from '~/queryClient';
import { useGetApiDancers } from '~/hookgen/dancer/dancer';




const loader_array = [eventLoader, competitionLoader, bibsListLoader, dancerListLoader];


export async function loader({ params }: Route.LoaderArgs) {

    const combinedData = await combineServerLoader(loader_array, params);
    return combinedData;
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

        return serverData;
    }

    const combinedData = await combineClientLoader(loader_array, params);
    return combinedData;
}
clientLoader.hydrate = true;


function BibHomePublic({ loaderData }: Route.ComponentProps) {

    const { data: bibs_list } = useGetApiCompIdBibs(loaderData.id_competition, {
        query: {
            initialData: loaderData.bibs_list,
        }
    });

    const { data: dancer_list } = useGetApiDancers({
        query: {
            initialData: loaderData.dancer_list,
        }
    });

    return (
        <>
            <h1>Compétition {loaderData.competition_data.name}</h1>
            <h2>Ajouter une compétiteurice</h2>
            <SelectNewBibFormComponent id_competition={loaderData.id_competition} bibs_list={bibs_list} dancer_list={dancer_list}/>
        </>
    );
}

export default BibHomePublic;

export const handle = {
    breadcrumb: () => "New"
};
