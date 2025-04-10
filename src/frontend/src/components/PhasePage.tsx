import "../styles/ContentStyle.css";

import React from 'react';
import { useGetApiCompId } from '../hookgen/competition/competition';

import PageTitle from "./PageTitle";
import Header from "./Header";
import Footer from "./Footer";
import { CompetitionId } from "hookgen/model";
import { Link, useParams } from "react-router";
import { useGetApiEventId } from "hookgen/event/event";
import NewPhaseForm from "./NewPhaseForm";
import PhaseList from "./PhaseList";
import { useGetApiPhaseId } from "hookgen/phase/phase";

function PhasePage() {

    let { id_phase } = useParams();
    let id_competition_number = parseInt(id_phase) as CompetitionId;
    const { data, isLoading } = useGetApiPhaseId(id_competition_number);


    const phase = data?.data;

    const {data: dataComp} = useGetApiCompId(phase?.competition)

    const { data: dataEvent } = useGetApiEventId(parseInt(competition?.event));
    const event = dataEvent?.data;

    if (isLoading) return <div>Chargement...</div>;
    if (!data) return null;

    return (
        <>
            <PageTitle title={"Compétition " + competition?.name} />
            <Header />
            <div className="content-container">

                <h1>Compétition {competition?.name}</h1>


                <p><Link to={`/events/${competition?.event}`}>
                    Evénement {event?.name}
                </Link></p>
                <p>Type : {competition?.kind}</p>
                <p>Catégorie : {competition?.category}</p>
                <PhaseList id_competition={id_competition_number} />
                <NewPhaseForm default_competition={id_competition_number} />
            </div>
            <Footer />
        </>
    );
}

export default PhasePage;