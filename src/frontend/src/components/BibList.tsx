import "../styles/ContentStyle.css";

import React from 'react';
import { useGetApiDancerId } from '@hookgen/dancer/dancer';

import { Bib, CompetitionId, CoupleTarget, RoleItem, SingleTarget, Target } from "@hookgen/model";
import { Link } from "react-router";
import PageTitle from "./PageTitle";
import Header from "./Header";
import Footer from "./Footer";
import { useGetApiCompIdDancers } from "@hookgen/competition/competition";

const dancerLink = "dancer/"

function convert_target(target: Target | undefined) {

    if (target === undefined) {
        return []
    }

    if (target.target_type === "single") {
        const single_target = [target as SingleTarget];

        return single_target;
    } else {
        const couple_target = target as CoupleTarget;
        const single_target: SingleTarget[] = [
            { target_type: "single", target: couple_target.leader, role: [RoleItem.Leader] },
            { target_type: "single", target: couple_target.follower, role: [RoleItem.Follower] },

        ];

        return single_target;
    }

}

function convert_bib_to_single_target(bib: Bib): Bib[] {

    const single_target_array = convert_target(bib?.target);
    return single_target_array.map((t, index) => ({ ...bib, target: t }));

}

export function BareBibListComponent({ bib_list }: { bib_list: Array<Bib> }) {

    const single_target_array = bib_list.flatMap((bib, index) => convert_bib_to_single_target(bib));

    console.log(single_target_array);

    return (
        <>
            <h1>Liste Compétiteur-ices</h1>
            <table>
                <tbody>
                    <tr>
                        <th>Nom</th>
                        <th>Prénom</th>
                        <th>Bib</th>
                        <th>Role</th>
                    </tr>

                    {single_target_array.map((bibObject, index) => (
                        <BibDetails bib_object={bibObject} index={index} />
                    ))}
                </tbody>
            </table>
        </>
    );
}

function BibDetails({ bib_object, index }: { bib_object: Bib, index: number }) {

    const single_target = bib_object.target as SingleTarget;
    const id = single_target.target as number;
    const { data, isLoading } = useGetApiDancerId(id);

    if (isLoading) return <div>Chargement...</div>;
    if (!data) return null;

    const dancer = data.data;
    return (
        <tr key={index}
            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
            <td>
                <Link to={`/${dancerLink}${single_target.target}`}>
                    {dancer.last_name}
                </Link>
            </td>
            <td>
                <Link to={`/${dancerLink}${id}`}>
                    {dancer.first_name}
                </Link>
            </td>
            <td>{bib_object.bib}</td>
            <td>{single_target.role}</td>
        </tr>

    );
}

function BibListComponent({id_competition} : {id_competition: CompetitionId}) {

    const { data, isLoading, error } = useGetApiCompIdDancers(id_competition);

    if (isLoading) return <div>Chargement des compétiteur-euses...</div>;
    if (error) return <div>Erreur: {(error as any).message}</div>;

    return (
        <>
            <BareBibListComponent bib_list={data?.data as Bib[]} />
        </>
    );
}

function BibList() {

    return (
        <>
            <PageTitle title="Événements" />
            <Header />
            <div className="content-container">

                <Link to={`/dancer/new`}>
                    Créer un-e nouvel-le compétiteur-euse
                </Link>
                <p>Attention, lien unique vers la compétition 1</p>
                <BibListComponent id_competition={1} />
            </div>

            <Footer />
        </>
    );
}

export default BibList;