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

function CompetitionPage() {

    let { id_competition } = useParams();
    let id_competition_number = Number(id_competition) as CompetitionId;
    const { data, isLoading, isError, error } = useGetApiCompId(id_competition_number);


    const competition = data?.data;

    const { data: dataEvent } = useGetApiEventId(Number(competition?.event));
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

export default CompetitionPage;
