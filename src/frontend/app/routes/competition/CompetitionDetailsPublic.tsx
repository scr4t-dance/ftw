import type { Route } from "./+types/CompetitionDetailsPublic"

import type { BibList, Competition, } from "@hookgen/model";
import { BareBibListComponent } from "@routes/bib/BibComponents";
import { useGetApiCompIdBibs } from "~/hookgen/bib/bib";
import { bibsListLoader, combineClientLoader, combineServerLoader, competitionLoader, eventLoader, queryClient } from "~/queryClient";

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

export default function CompetitionDetails({
    params,
    loaderData,
}: Route.ComponentProps) {

    const competition = loaderData.competition_data as Competition;

    const { data: bibs_list } = useGetApiCompIdBibs(loaderData.id_competition, {
        query: {
            initialData: loaderData.bibs_list,
        }
    });

    return (
        <>
            <h1>Compétition {competition?.name}</h1>
            <p>Type : {competition?.kind}</p>
            <p>Catégorie : {competition?.category}</p>
            <BareBibListComponent bib_list={bibs_list.bibs} />
        </>
    );
}
