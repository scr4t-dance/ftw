import "~/styles/ContentStyle.css";

import React from 'react';
import { useGetApiCompId } from '@hookgen/competition/competition';

import type { ArtefactDescription, CompetitionId, EventId, PhaseId } from "@hookgen/model";
import { Link, useParams } from "react-router";
import { useGetApiEventId } from "@hookgen/event/event";
import { useGetApiPhaseId } from "@hookgen/phase/phase";
import ArtefactDescriptionComponent from "../competition/ArtefactDescription";

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
                    <Link to={`/events/${competition?.event}`}>
                        Evénement {event?.name}
                    </Link>
                </p>
                <div>Notation juges :
                    <ArtefactDescriptionComponent
                        artefact_description={phase?.judge_artefact_descr as ArtefactDescription}
                    />
                </div>
                <div>Notation head juge :
                    <ArtefactDescriptionComponent
                        artefact_description={phase?.head_judge_artefact_descr as ArtefactDescription}
                    />
                </div>
                <p>Catégorie : {competition?.category}</p>

        </>
    );
}

export default PhasePage;