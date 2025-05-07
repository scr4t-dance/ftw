import "~/styles/ContentStyle.css";

import React from 'react';
import { useGetApiCompId} from '@hookgen/competition/competition';
import { useGetApiEventIdComps } from "@hookgen/event/event";

import { type CompetitionId, type CompetitionIdList, type EventId } from "@hookgen/model";
import { Link } from "react-router";
import { useQueryClient } from "@tanstack/react-query";

const competitionListlink = "competitions/"

function CompetitionList({ id_event }: {id_event: EventId}) {

    console.log("competition list", id_event)
    const { data, isLoading, error, queryKey } = useGetApiEventIdComps(id_event);

    console.log("competitionList queryKey", queryKey)
    const competition_array = data?.data as CompetitionIdList;


    const queryClient = useQueryClient();
    console.log("competitionList cache", queryClient.getQueryCache().getAll().map(q => q.queryKey));

    if (isLoading) return <div>Chargement des compétitions...</div>;
    if (error) return <div>Erreur: {(error as any).message}</div>;

    return (
        <>
            <h2>Liste Compétitions</h2>
            <table>
                <tbody>
                    <tr>
                        <th>Nom de la compétition</th>
                        <th>Type</th>
                        <th>Catégorie</th>
                    </tr>

                    {competition_array.competitions.map((competitionId, index) => (
                        <CompetitionDetails key={competitionId} id={competitionId} index={index}/>
                    ))}
                </tbody>
            </table>
        </>
    );
}


function CompetitionDetails({ id, index }: { id: CompetitionId, index: number }) {
  const { data, isLoading } = useGetApiCompId(id);

  if (isLoading) return <div>Chargement...</div>;
  if (!data) return null;

  const competition = data.data;
  const kind = competition.kind;
  const category = competition.category;

  return (
    <tr key={id}
        className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
        <td>
        <Link to={`/${competitionListlink}${id}`}>
            {competition.name}
        </Link>
        </td>
        <td>{kind}</td>
        <td>{category}</td>
    </tr>

  );
}

export default CompetitionList;