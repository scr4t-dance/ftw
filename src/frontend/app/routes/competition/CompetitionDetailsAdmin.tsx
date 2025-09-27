import type { Route } from "./+types/CompetitionDetailsAdmin"

import { Link } from "react-router";


import { getApiCompId } from '@hookgen/competition/competition';
import { getApiCompIdBibs } from '@hookgen/bib/bib';

import type { BibList, Competition, CompetitionId, Event, EventId } from "@hookgen/model";
import { NewPhaseFormComponent } from "@routes/phase/NewPhaseForm";
import { PhaseList } from "@routes/phase/PhaseList";
import { NewBibForm } from "@routes/bib/NewBibForm";
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

    const id_competition = loaderData.id_competition as CompetitionId;
    const competition = loaderData.competition_data as Competition;
    const event = loaderData.event_data as Event;
    const bib_list = loaderData.bib_data as BibList;

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
            <PhaseList id_competition={id_competition} competition_data={competition} />
            <NewPhaseFormComponent id_competition={id_competition} />
            <BareBibListComponent bib_list={bib_list.bibs} />
            <NewBibForm default_competition={id_competition} />
        </>
    );
}
