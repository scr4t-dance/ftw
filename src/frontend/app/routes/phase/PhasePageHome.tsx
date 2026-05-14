import type { Route } from './+types/PhasePageHome';

import React from 'react';
import { NavLink, Outlet, type UIMatch } from "react-router";
import { dehydrate, QueryClient } from '@tanstack/react-query';
import { getGetApiEventIdQueryOptions } from '@hookgen/event/event';
import { getGetApiCompIdQueryOptions } from '@hookgen/competition/competition';
import { getGetApiPhaseIdQueryOptions } from '@hookgen/phase/phase';
import type { CompetitionId, EventId, PhaseId } from '~/hookgen/model';
import { PhasePageNavigationComponent } from './PhaseComponents';

export async function loader({ params }: Route.LoaderArgs) {

    const queryClient = new QueryClient();
    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;
    const id_phase = Number(params.id_phase) as PhaseId;

    await queryClient.prefetchQuery(getGetApiEventIdQueryOptions(id_event));
    await queryClient.prefetchQuery(getGetApiCompIdQueryOptions(id_competition));
    await queryClient.prefetchQuery(getGetApiPhaseIdQueryOptions(id_phase));

    return { dehydratedState: dehydrate(queryClient) };
}


function PhasePageHome({ params }: Route.ComponentProps) {

    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;
    const id_phase = Number(params.id_phase) as PhaseId;

    return (
        <>
            <PhasePageNavigationComponent id_phase={id_phase} id_competition={id_competition} />
            <Outlet />
        </>
    );
}

export default PhasePageHome;

export const handle = {
    breadcrumb: (match: UIMatch) =>
        <div className="main-nav">
            <span>
                <NavLink to={match.pathname}>Phase</NavLink>
            </span>
            <div className="sub-nav">
                <ol>
                    <li>
                        <NavLink to={`${match.pathname}/edit_judges`}>
                            Modifier les Juges
                        </NavLink>
                    </li>
                    <li>
                        <NavLink to={`${match.pathname}/judges`}>
                            Juges
                        </NavLink>
                    </li>
                    <li>
                        <NavLink to={`${match.pathname}/pairings`}>
                            Appairage
                        </NavLink>
                    </li>
                    <li>
                        <NavLink to={`${match.pathname}/edit`}>
                            Modifier les paramètres de la Phase
                        </NavLink>
                    </li>
                    <li>
                        <NavLink to={`${match.pathname}/heats`}>
                            Poules
                        </NavLink>
                    </li>
                    <li>
                        <NavLink to={`${match.pathname}/artefacts`}>
                            Scoring pour juges
                        </NavLink>
                    </li>
                    <li>
                        <NavLink to={`${match.pathname}/artefacts/?for=scorer`}>
                            Espace Scoreur
                        </NavLink>
                    </li>
                    <li>
                        <NavLink to={`${match.pathname}/ranks`}>
                            Classement
                        </NavLink>
                    </li>
                </ol>
            </div>
        </div>
};
