import "../styles/ContentStyle.css";

import React from 'react';
import { useGetApiDancerId } from '../hookgen/dancer/dancer';

import PageTitle from "./PageTitle";
import Header from "./Header";
import Footer from "./Footer";
import { DancerId, Date } from "hookgen/model";
import { useParams } from "react-router";

function DancerPage() {

    let { id_dancer } = useParams();
    let id_dancer_number = Number(id_dancer) as DancerId;
    const { data, isLoading, isError, error } = useGetApiDancerId(id_dancer_number);

    if (isLoading) return <div>Chargement...</div>;
    if (!data) return null;

    const dancer = data.data;

    if (isLoading) return <div>Chargement des événements...</div>;
    if (isError) return <div>Erreur: {(error as any).message}</div>;

    return (
        <>
            <PageTitle title={"Compétiteurice " + dancer?.last_name + " " + dancer.first_name} />
            <Header />
            <div className="content-container">

                <h1>{dancer?.last_name + " " + dancer.first_name}</h1>
                <p>Division follower : {dancer?.as_follower}</p>
                <p>Division leader : {dancer?.as_leader}</p>
                <p>Birthday: "Hidden"</p>
                <p>Email : "Hidden"</p>
            </div>
            <Footer />
        </>
    );
}

export default DancerPage;