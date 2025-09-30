
import React from 'react';
import { Link, useLocation } from "react-router";
import { useQueries } from "@tanstack/react-query";

import { getGetApiCompIdQueryOptions } from '@hookgen/competition/competition';
import { useGetApiEventIdComps } from "@hookgen/event/event";
import { type CompetitionIdList, type EventId } from "@hookgen/model";

export function CompetitionTable({ id_event, competition_id_list }: { id_event: EventId, competition_id_list: CompetitionIdList }) {

  const location = useLocation();
  const url = location.pathname.includes("competition") ? "" : "competitions/";

  const competitionDetailsQueries = useQueries({
    queries: competition_id_list.competitions.map((competitionId) => ({
      ...getGetApiCompIdQueryOptions(competitionId),
      enabled: true,
    })),
  });


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
                  <Link to={`${url}${competitionId}`}>
                    {competition.name}
                  </Link>
                </td>
                <td>{competition.kind}</td>
                <td>{competition.category}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </>
  );
}

export function CompetitionListComponent({ id_event }: { id_event: EventId }) {

  console.log("CompetitionList", id_event);

  const { data: competitionList, isLoading, isError, error } = useGetApiEventIdComps(
    id_event,
  );

  if (isLoading) return <div>Chargement des compétitions...</div>;
  if (isError) return <div>Erreur: {(error as any).message}</div>;

  if (!competitionList || !competitionList.competitions || competitionList.competitions.length === 0) {
    return <div>Aucune compétition disponible pour cet événement.</div>;
  }

  return (
    <>
      <CompetitionTable id_event={id_event} competition_id_list={competitionList as CompetitionIdList} />
    </>
  );
}
