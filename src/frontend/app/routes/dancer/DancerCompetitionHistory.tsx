import "~/styles/ContentStyle.css";

import React from 'react';
import { Link, useParams } from "react-router";

import { type DancerId } from "@hookgen/model";
import { useGetApiDancerIdCompetitionHistory } from '@hookgen/dancer/dancer';
import { useQueries } from "@tanstack/react-query";
import { getGetApiCompIdQueryOptions } from "~/hookgen/competition/competition";


function DancerCompetitionHistory() {

    let { id_dancer } = useParams();
    let id_dancer_number = Number(id_dancer) as DancerId;

    /* todo regarder les résultats */
    const { data: competition_id_list, isLoading, isError, error } = useGetApiDancerIdCompetitionHistory(id_dancer_number);

    const competitionDetailsQueries = useQueries({
        queries: competition_id_list.competitions.map((competitionId) => ({
            ...getGetApiCompIdQueryOptions(competitionId),
            enabled: true,
        })),
    });


    if (isLoading) return null;
    if (!competition_id_list) return null;

    const isDetailsLoading = competitionDetailsQueries.some((query) => query.isLoading);
    const isDetailsError = competitionDetailsQueries.some((query) => query.isError);

    if (isDetailsLoading) return <div>Loading competition details...</div>;
    if (isDetailsError) return (
        <div>
            Error loading competition details
            {
                competitionDetailsQueries.map((query) => {
                    return (<p>{query.error?.message}</p>);
                })
            }
        </div>);


    return (
        <>
            <h2>Liste Compétitions</h2>
            <table>
                <thead>
                    <tr>
                        <th>Nom de la compétition</th>
                        <th>Type</th>
                        <th>Catégorie</th>
                        <th>Résultat</th>
                    </tr>
                </thead>
                <tbody>

                    {competitionDetailsQueries.map((competitionDetailsQuery, index) => {
                        const competitionId = competition_id_list.competitions[index];
                        const competition = competitionDetailsQuery.data;

                        if (!competition) return null;

                        return (
                            <tr key={index} className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
                                <td>
                                    <Link to={`/competitions/${competitionId}`}>
                                        {competition.name}
                                    </Link>
                                </td>
                                <td>{competition.kind}</td>
                                <td>{competition.category}</td>
                                <td>TODO</td>
                            </tr>
                        );
                    })}
                </tbody>
            </table>
        </>
    );
}

export default DancerCompetitionHistory;