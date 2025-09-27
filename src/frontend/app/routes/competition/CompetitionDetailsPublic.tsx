import type { Route } from "./+types/CompetitionDetailsPublic"

import { Link } from "react-router";


import { getApiCompId } from '@hookgen/competition/competition';
import { getApiCompIdBibs } from '@hookgen/bib/bib';

import type { BibList, Competition, CompetitionId, EventId } from "@hookgen/model";
import { BareBibListComponent } from "@routes/bib/BibList";
import { getApiEventId, getApiEventIdComps } from "@hookgen/event/event";


export async function loader({ params }: Route.LoaderArgs) {

    let id_event = Number(params.id_event) as EventId;
    const event_data = await getApiEventId(id_event);
    const competition_list = await getApiEventIdComps(id_event);
    const id_competition = Number(params.id_competition) as CompetitionId;
    const competition_data = await getApiCompId(id_competition);
    const bib_data = await getApiCompIdBibs(id_competition);
    return {
        id_event,
        id_competition,
        event_data,
        competition_list,
        competition_data,
        bib_data,
    };
}

export default function CompetitionDetails({
    params,
    loaderData,
}: Route.ComponentProps) {

    const competition = loaderData.competition_data as Competition;
    const bib_list = loaderData.bib_data as BibList;

    return (
        <>
            <h1>Compétition {competition?.name}</h1>
            <p>Type : {competition?.kind}</p>
            <p>Catégorie : {competition?.category}</p>
            <BareBibListComponent bib_list={bib_list.bibs} />
        </>
    );
}
