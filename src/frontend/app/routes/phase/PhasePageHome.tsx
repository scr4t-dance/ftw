import React from 'react';
import { useGetApiCompId } from '@hookgen/competition/competition';

import type { CompetitionId, EventId, PhaseId } from "@hookgen/model";
import { Link, Outlet, useParams } from "react-router";
import { useGetApiEventId } from "@hookgen/event/event";
import { useGetApiPhaseId } from "@hookgen/phase/phase";
import { EditPhaseForm } from "./EditPhaseForm";

function PhasePageHome() {

    let { id_phase } = useParams();
    let id_phase_number = Number(id_phase) as PhaseId;
    const { data, isLoading } = useGetApiPhaseId(id_phase_number);


    const phase = data;

    const { data: dataComp } = useGetApiCompId(phase?.competition as CompetitionId)
    const competition = dataComp;
    const { data: dataEvent } = useGetApiEventId(competition?.event as EventId);
    const event = dataEvent;

    if (isLoading) return <div>Chargement...</div>;
    if (!data) return null;

    return (
        <>
            <h1>Phase {phase?.round} {competition?.name}</h1>

            <p>
                <Link to={`/phases/${id_phase_number}`}>
                    Phase
                </Link>
            </p>
            <p>
                <Link to={`/phases/${id_phase_number}/heats`}>
                    Phase Heats
                </Link>
            </p>
            <p>
                <Link to={`/phases/${id_phase_number}/artefacts`}>
                    Phase Artefacts
                </Link>
            </p>
            <p>
                <Link to={`/phases/${id_phase_number}/judges`}>
                    Phase Judges
                </Link>
            </p>
            <p>
                <Link to={`/phases/${id_phase_number}/edit_judges`}>
                    Edit Phase Judges
                </Link>
            </p>
            <p>
                <Link to={`/competitions/${phase?.competition}`}>
                    Competition {event?.name}
                </Link>
            </p>
            <p>
                <Link to={`/events/${competition?.event}`}>
                    Evénement {event?.name}
                </Link>
            </p>
            <p>Catégorie : {competition?.category}</p>
            <Outlet />

        </>
    );
}

export default PhasePageHome;