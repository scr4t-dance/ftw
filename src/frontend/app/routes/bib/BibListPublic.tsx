
import React from 'react';
import { Link } from "react-router";
import {
    type BibList, type CompetitionId, type EventId,
} from "@hookgen/model";

import { getApiCompIdBibs } from "@hookgen/bib/bib";

import type { Route } from './+types/BibListPublic';
import { getApiCompId } from '@hookgen/competition/competition';
import { getApiEventId } from '@hookgen/event/event';
import { BareBibListComponent } from '@routes/bib/BibComponents';


const dancerLink = "dancers/"


export async function loader({ params }: Route.LoaderArgs) {

    const id_event = Number(params.id_event) as EventId;
    const event_data = getApiEventId(id_event);
    const id_competition =  Number(params.id_competition) as CompetitionId;
    const competition_data = getApiCompId(id_competition);
    const bibs_list = await getApiCompIdBibs(id_competition);
    return {
        id_event,
        event_data,
        id_competition,
        competition_data,
        bibs_list,
    };
}


function BibList({
    loaderData
}: Route.ComponentProps) {

    return (
        <>
            <Link to={`/${dancerLink}new`}>
                Créer un-e nouvel-le compétiteur-euse
            </Link>
            <BareBibListComponent bib_list={loaderData.bibs_list.bibs} />
        </>
    );
}

export default BibList;