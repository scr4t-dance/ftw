import type { Route } from "./+types/CompetitionList"

import React from 'react';

import { getApiEventId, getApiEventIdComps } from "@hookgen/event/event";
import { type CompetitionIdList, type EventId } from "@hookgen/model";
import { CompetitionTable } from "@routes/competition/CompetitionComponents";


export async function loader({ params }: Route.LoaderArgs) {

    let id_event = Number(params.id_event) as EventId;
    const event_data = await getApiEventId(id_event);
    const competition_list = await getApiEventIdComps(id_event);
    return {
        id_event,
        event_data,
        competition_list,
    };
}

export default function CompetitionList({
    params,
    loaderData
} : Route.ComponentProps) {

    return (
        <>
            <CompetitionTable id_event={loaderData.id_event} competition_id_list={loaderData.competition_list as CompetitionIdList} />
        </>
    );
}
