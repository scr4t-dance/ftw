import "../styles/ContentStyle.css";

import React from 'react';
import { useGetApiCompId } from '../hookgen/competition/competition';

import PageTitle from "./PageTitle";
import Header from "./Header";
import Footer from "./Footer";
import { ArtefactDescription, CompetitionId, EventId, PhaseId } from "hookgen/model";
import { Link, useParams } from "react-router";
import { useGetApiEventId } from "hookgen/event/event";
import { useGetApiPhaseId } from "hookgen/phase/phase";
import ArtefactDescriptionComponent from "./ArtefactDescription";

function PhasePage() {

    let { id_phase } = useParams();
    let id_phase_number = Number(id_phase) as PhaseId;
    const { data, isLoading } = useGetApiPhaseId(id_phase_number);


    const phase = data?.data;

    const { data: dataComp } = useGetApiCompId(phase?.competition as CompetitionId)
    const competition = dataComp?.data;
    const { data: dataEvent } = useGetApiEventId(competition?.event as EventId);
    const event = dataEvent?.data;

    if (isLoading) return <div>Chargement...</div>;
    if (!data) return null;

    return (
        <>
            <PageTitle title={"Phase " + phase?.round + " " + competition?.name} />
            <Header />
            <div className="content-container">

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

            </div>
            <Footer />
        </>
    );
}

export default PhasePage;