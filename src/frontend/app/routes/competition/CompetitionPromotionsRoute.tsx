import type { Route } from "./+types/CompetitionPromotionsRoute"

import { Link } from "react-router";

import type { BibList, Competition, CompetitionId, Event, EventId } from "@hookgen/model";
import { NewPhaseFormComponent } from "@routes/phase/NewPhaseForm";
import { NewBibFormComponent } from "~/routes/bib/NewBibFormComponent";
import { BareBibListComponent } from "@routes/bib/BibComponents";
import { combineClientLoader, combineServerLoader, competitionLoader, eventLoader, promotionsLoader, queryClient, resultsLoader } from "~/queryClient";
import { PhaseListComponent } from "../phase/PhaseComponents";
import { useGetApiCompIdPromotions, useGetApiCompIdResults } from "~/hookgen/results/results";
import { CompetitionNavigation, CompetitionResults } from "./CompetitionComponents";



const loader_array = [eventLoader, competitionLoader, resultsLoader, promotionsLoader];


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


export default function CompetitionPromotions({
    params,
    loaderData,
}: Route.ComponentProps) {

    const id_competition = loaderData.id_competition as CompetitionId;
    const competition = loaderData.competition_data as Competition;

    //const url = `/events/${loaderData.id_event}/competitions/${loaderData.id_competition}`;
    const url = "../";

    return (
        <>
            <h1>Compétition {competition?.name}</h1>
            <CompetitionNavigation url={url} />
            <p>Type : {competition?.kind}</p>
            <p>Catégorie : {competition?.category}</p>
            <CompetitionResults id_competition={loaderData.id_competition} results_data={loaderData.results_data} promotions_data={loaderData.promotions_data} />
        </>
    );
}
