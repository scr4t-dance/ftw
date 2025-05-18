import "../styles/ContentStyle.css";

import React from 'react';
import { useGetApiCompId} from '../hookgen/competition/competition';
import { useGetApiEventIdComps } from "hookgen/event/event";

import { CompetitionId, EventId } from "hookgen/model";
import { Link } from "react-router";

const competitionListlink = "competitions/"

function CompetitionList({ id_event }: {id_event: EventId}) {

    const { data, isLoading, error } = useGetApiEventIdComps(id_event);

    if (isLoading) return <div>Chargement des compétitions...</div>;
    if (error) return <div>Erreur: {(error as any).message}</div>;

    return (
        <>
            <h1>Liste Compétitions</h1>
            <table>
                <tbody>
                    <tr>
                        <th>Nom de la compétition</th>
                        <th>Type</th>
                        <th>Catégorie</th>
                    </tr>

                    {data?.data.competitions?.map((competitionId, index) => (
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