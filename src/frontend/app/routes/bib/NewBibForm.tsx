
import React from 'react';

import type { Route } from './+types/NewBibForm';
import { NewBibFormComponent } from '@routes/bib/NewBibFormComponent';
import { useGetApiCompIdBibs } from '@hookgen/bib/bib';
import { bibsListLoader, combineClientLoader, combineServerLoader, competitionLoader, eventLoader, queryClient, type LoaderOutput, type WithEntityData } from '~/queryClient';




const loader_array = [eventLoader, competitionLoader, bibsListLoader];


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
        }
    );

    return (
        <>
            <h1>Compétition {loaderData.competition_data.name}</h1>
            <h2>Ajouter une compétiteurice</h2>
            <NewBibFormComponent id_competition={loaderData.id_competition} bibs_list={bibs_list} />
        </>
    );
}

export default BibHomePublic;

export const handle = {
  breadcrumb: () => "New"
};
