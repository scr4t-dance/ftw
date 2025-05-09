import "~/styles/ContentStyle.css";

import React from 'react';
import { useParams } from "react-router";

import PageTitle from "@routes/index/PageTitle";
import Header from "@routes/header/header";
import Footer from "@routes/footer/footer";

import { type DancerId, type Date } from "@hookgen/model";
import { useGetApiDancerId } from '@hookgen/dancer/dancer';

function DancerPage() {

    let { id_dancer } = useParams();
    let id_dancer_number = Number(id_dancer) as DancerId;
    const { data, isLoading, isError, error } = useGetApiDancerId(id_dancer_number);

    if (isLoading) return <div>Chargement...</div>;
    if (!data) return null;

    const dancer = data;

    if (isLoading) return <div>Chargement des événements...</div>;
    if (isError) return <div>Erreur: {(error as any).message}</div>;

    return (
        <>
            <h1>{dancer?.last_name + " " + dancer.first_name}</h1>
            <p>Division follower : {dancer?.as_follower}</p>
            <p>Division leader : {dancer?.as_leader}</p>
            <p>Birthday: "Hidden"</p>
            <p>Email : "Hidden"</p>
            <p>List de compétitions: TODO</p>
        </>
    );
}

export default DancerPage;