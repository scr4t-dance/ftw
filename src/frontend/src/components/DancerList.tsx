import "../styles/ContentStyle.css";

import React from 'react';
import { useGetApiDancers, useGetApiDancerId } from '@hookgen/dancer/dancer';

import { DancerId, DancerIdList } from "@hookgen/model";
import { Link } from "react-router";
import PageTitle from "./PageTitle";
import Header from "./Header";
import Footer from "./Footer";

const dancerLink = "dancer/"

export function BareDancerListComponent({dancer_list} : {dancer_list : DancerIdList}) {

    return (
        <>
            <h1>Liste Compétiteur-ices</h1>
            <table>
                <tbody>
                    <tr>
                        <th>Nom</th>
                        <th>Prénom</th>
                        <th>Division follower</th>
                        <th>Division leader</th>
                    </tr>

                    {dancer_list?.dancers?.map((dancerId, index) => (
                        <DancerDetails key={dancerId} id={dancerId} index={index} />
                    ))}
                </tbody>
            </table>
        </>
    );
}

function DancerListComponent() {

    const { data, isLoading, error } = useGetApiDancers();

    if (isLoading) return <div>Chargement des compétiteur-euses...</div>;
    if (error) return <div>Erreur: {(error as any).message}</div>;

    return (
        <>
            <BareDancerListComponent dancer_list={data?.data as DancerIdList} />
        </>
    );
}


function DancerDetails({ id, index }: { id: DancerId, index: number }) {
    const { data, isLoading } = useGetApiDancerId(id);

    if (isLoading) return <div>Chargement...</div>;
    if (!data) return null;

    const dancer = data.data;

    return (
        <tr key={id}
            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
            <td>
                <Link to={`/${dancerLink}${id}`}>
                    {dancer.last_name}
                </Link>
            </td>
            <td>
                <Link to={`/${dancerLink}${id}`}>
                    {dancer.first_name}
                </Link>
            </td>
            <td>{dancer.as_follower}</td>
            <td>{dancer.as_leader}</td>
        </tr>

    );
}

function DancerList() {

    return (
        <>
            <PageTitle title="Événements" />
            <Header />
            <div className="content-container">

                <Link to={`/dancer/new`}>
                    Créer un-e nouvel-le compétiteur-euse
                </Link>
                <DancerListComponent />
            </div>

            <Footer />
        </>
    );
}

export default DancerList;