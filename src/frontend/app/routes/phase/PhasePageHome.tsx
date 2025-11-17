import type { Route } from './+types/PhasePageHome';

import React from 'react';
import { Link, Outlet } from "react-router";

import { getApiCompId } from '@hookgen/competition/competition';
import type { CompetitionId, EventId, PhaseId } from "@hookgen/model";
import { getApiEventId, getApiEventIdComps } from "@hookgen/event/event";
import { getApiCompIdPhases, getApiPhaseId } from "@hookgen/phase/phase";

export async function loader({ params }: Route.LoaderArgs) {

    let id_event = Number(params.id_event) as EventId;
    const event_data = await getApiEventId(id_event);
    const competition_list = await getApiEventIdComps(id_event);
    const id_competition = Number(params.id_competition) as CompetitionId;
    const competition_data = await getApiCompId(id_competition);
    const phase_list = await getApiCompIdPhases(id_competition);
    const id_phase = Number(params.id_phase) as PhaseId;
    const phase_data = await getApiPhaseId(id_phase);
    return {
        id_event,
        id_competition,
        event_data,
        competition_list,
        competition_data,
        phase_list,
        id_phase,
        phase_data,
    };
}


function PhasePageHome({
    loaderData
}: Route.ComponentProps) {

    //const url = `/events/${loaderData.id_event}/competitions/${loaderData.id_competition}/phases/${loaderData.id_phase}`;
    const url = '';
    const phase = loaderData.phase_data;
    const competition = loaderData.competition_data;

    return (
        <>
            <div className="no-print">
                <h1>Phase {phase?.round} {competition?.name}</h1>
                <p>
                    <Link to={`${url}edit`}>
                        Edit Phase
                    </Link>
                </p>
                <p>
                    <Link to={`${url}heats`}>
                        Poules
                    </Link>
                </p>
                <p>
                    <Link to={`${url}artefacts`}>
                        Scoring pour juges
                    </Link>
                </p>
                <p>
                    <Link to={`${url}artefacts/?for=scorer`}>
                        Espace Scoreur
                    </Link>
                </p>
                <p>
                    <Link to={`${url}ranks`}>
                        Classement
                    </Link>
                </p>
                <p>
                    <Link to={`${url}judges`}>
                        Phase Judges
                    </Link>
                </p>
                <p>
                    <Link to={`${url}edit_judges`}>
                        Edit Phase Judges
                    </Link>
                </p>
            </div>
            <Outlet />
        </>
    );
}

export default PhasePageHome;

export const handle = {
    breadcrumb: () => "Phase"
};
