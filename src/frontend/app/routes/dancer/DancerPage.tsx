import "~/styles/ContentStyle.css";

import React from 'react';
import { useParams } from "react-router";

import { type DancerId } from "@hookgen/model";
import { useGetApiDancerId } from '@hookgen/dancer/dancer';
import { SaveDancerFormComponent } from './NewDancerForm'


function DancerPage() {

    let { id_dancer } = useParams();
    let id_dancer_number = Number(id_dancer) as DancerId;

    const { data, isLoading, isError, error } = useGetApiDancerId(id_dancer_number);


    if (isLoading) return <div>Chargement...</div>;
    if (!data) return null;

    const dancer = data;

    if (isLoading) return <div>Chargement des informations de la danseureuse...</div>;
    if (isError) return <div>Erreur: {(error as any).message}</div>;

    return (
        <>
            <h1>{dancer?.last_name + " " + dancer.first_name}</h1>
            <p>Division follower : {dancer?.as_follower}</p>
            <p>Division leader : {dancer?.as_leader}</p>
            <p>Birthday: "Hidden"</p>
            <p>Email : "Hidden"</p>
            <p>List de compétitions: TODO</p>
            <h1>Mise à jour données</h1>
            <SaveDancerFormComponent id_dancer={id_dancer_number} dancer={dancer} />

        </>
    );
}

export default DancerPage;