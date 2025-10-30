import type { Route } from "./+types/CompetitionDetailsAdmin"

import { Link } from "react-router";


import { getApiCompId } from '@hookgen/competition/competition';
import { getApiCompIdBibs, useGetApiCompIdBibs } from '@hookgen/bib/bib';

import type { BibList, Competition, CompetitionId, Event, EventId } from "@hookgen/model";
import { NewPhaseFormComponent } from "@routes/phase/NewPhaseForm";
import { NewBibFormComponent } from "~/routes/bib/NewBibFormComponent";
import { BareBibListComponent } from "@routes/bib/BibComponents";
import { bibsListLoader, combineClientLoader, combineServerLoader, competitionLoader, eventLoader, phaseListLoader, queryClient } from "~/queryClient";
import { PhaseListComponent } from "../phase/PhaseComponents";
import { useGetApiCompIdPhases } from "~/hookgen/phase/phase";



const loader_array = [eventLoader, competitionLoader, bibsListLoader, phaseListLoader];


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


export default function CompetitionDetailsAdmin({
    params,
    loaderData,
}: Route.ComponentProps) {

    const id_competition = loaderData.id_competition as CompetitionId;
    const competition = loaderData.competition_data as Competition;

    const { data: bibs_list } = useGetApiCompIdBibs(loaderData.id_competition, {
        query: {
            initialData: loaderData.bibs_list,
        }
    });

    const { data: phase_list } = useGetApiCompIdPhases(loaderData.id_competition, {
        query: {
            initialData: loaderData.phase_list,
        }
    })

    //const url = `/events/${loaderData.id_event}/competitions/${loaderData.id_competition}`;
    const url = "";

    return (
        <>
            <h1>Compétition {competition?.name}</h1>
            <p>
                <Link to={`${url}phases`}>
                    Phases
                </Link>
            </p>
            <p>
                <Link to={`${url}bibs`}>
                    Bibs
                </Link>
            </p>
            <p>
                <Link to={`${url}phases/new`}>
                    Création Phase
                </Link>
            </p>
            <p>Type : {competition?.kind}</p>
            <p>Catégorie : {competition?.category}</p>
            <PhaseListComponent id_competition={id_competition} competition_data={competition} phase_list={loaderData.phase_list} />
            <NewPhaseFormComponent id_competition={id_competition} />
            <BareBibListComponent bib_list={bibs_list.bibs} />
            <NewBibFormComponent id_competition={id_competition} bibs_list={bibs_list} />
        </>
    );
}
