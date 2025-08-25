import React from 'react';
import { useGetApiCompId } from '@hookgen/competition/competition';

import type { CompetitionId, EventId, PhaseId } from "@hookgen/model";
import { Link, useParams } from "react-router";
import { useGetApiEventId } from "@hookgen/event/event";
import { useGetApiPhaseId } from "@hookgen/phase/phase";
import { EditPhaseForm } from "./EditPhaseForm";

function PhasePage() {

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
                <Link to={`/competitions/${phase?.competition}`}>
                    Competition {event?.name}
                </Link>
            </p>

            <p>
                <Link to={`/phases/${id_phase_number}/heats`}>
                    Phase Heats
                </Link>
            </p>
            <p>
                <Link to={`/events/${competition?.event}`}>
                    Evénement {event?.name}
                </Link>
            </p>
            <p>Catégorie : {competition?.category}</p>
            <EditPhaseForm phase_id={id_phase_number} />

        </>
    );
}

export default PhasePage;