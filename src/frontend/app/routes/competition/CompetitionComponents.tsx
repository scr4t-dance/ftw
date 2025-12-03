
import React from 'react';
import { Link, useLocation } from "react-router";
import { useQueries, useQueryClient } from "@tanstack/react-query";

import { getGetApiCompIdQueryOptions, useGetApiCompId } from '@hookgen/competition/competition';
import { useGetApiEventIdComps } from "@hookgen/event/event";
import { } from "@hookgen/model";
import { BibListComponent, PublicBibList } from '../bib/BibComponents';
import { useGetApiCompIdBibs } from '~/hookgen/bib/bib';
import { NewBibFormComponent } from '../bib/NewBibFormComponent';
import { useGetApiCompIdPhases } from '~/hookgen/phase/phase';
import { PhaseList } from '../phase/PhaseComponents';
import { NewPhaseFormComponent } from '../phase/NewPhaseForm';
import { useGetApiDancers } from '~/hookgen/dancer/dancer';
import {
  type Competition, type CompetitionId, type CompetitionIdList,
  type PhaseIdList,
  type DancerCompetitionResults, type DancerCompetitionResultsList, type Divisions, type EventId, type Promotion, type PromotionList
} from "@hookgen/model";
import { get_rang } from '../dancer/DancerCompetitionHistory';
import { DancerCell } from '../bib/BibComponents';
import { Badge } from '../dancer/DancerComponents';
import { getGetApiCompIdPromotionsQueryKey, getGetApiCompIdResultsQueryKey, usePutApiCompIdPromotions } from '~/hookgen/results/results';

export function CompetitionTable({ competition_id_list, competition_data_list }: { competition_id_list: CompetitionIdList, competition_data_list: Competition[] }) {

  const location = useLocation();
  const url = location.pathname.includes("competition") ? "" : "competitions/";

  return (
    <>
      <h2>Liste Compétitions 2</h2>
      <table>
        <thead>
          <tr>
            <th>Nom de la compétition</th>
            <th>Type</th>
            <th>Catégorie</th>
          </tr>
        </thead>
        <tbody>

          {competition_data_list.map((competition, index) => {
            const competitionId = competition_id_list.competitions[index];

            if (!competition) return null;

            return (
              <tr key={index} className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
                <td>
                  <Link to={`${url}${competitionId}`}>
                    {competition.name === "" ? "unnamed" : competition.name}
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


export function CompetitionTableComponent({ id_event, competition_id_list }: { id_event: EventId, competition_id_list: CompetitionIdList }) {

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

  const competition_data_list = competitionDetailsQueries.map(q => q.data as Competition);

  return (
    <CompetitionTable competition_id_list={competition_id_list} competition_data_list={competition_data_list} />
  );
}

export function EventCompetitionListComponent({ id_event }: { id_event: EventId }) {

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
      <CompetitionTableComponent id_event={id_event} competition_id_list={competitionList as CompetitionIdList} />
    </>
  );
}

export function CompetitionNavigation({ url }: { url: string }) {

  return (
    <>
      <p>
        <Link to={`${url}phases`}>
          Phases
        </Link>
      </p>
      <p>
        <Link to={`${url}bibs`}>
          Bibs
        </Link>
      </p>
      <p>
        <Link to={`${url}phases/new`}>
          Création Phase
        </Link>
      </p>
      <p>
        <Link to={`${url}promotions`}>
          Résultats/Promotions
        </Link>
      </p>
    </>
  );

}

export function CompetitionDetailsComponent({ id_competition, isAdmin }: { id_competition: CompetitionId, isAdmin: boolean }) {

  const { data: competition, isLoading: isLoadingCompetition, isError: isErrorCompetition } = useGetApiCompId(id_competition)
  const { data: bibs_list, isLoading: isLoadingBibs, isError: isErrorBibs } = useGetApiCompIdBibs(id_competition);

  const { data: phase_list } = useGetApiCompIdPhases(id_competition);
  const { data: dancer_list } = useGetApiDancers();

  if (isLoadingCompetition) return (<div>Chargement de la competition</div>);
  if (isErrorCompetition) return (<div>Erreur chargement de la competition</div>);

  if (isLoadingBibs) return (<div>Chargement des dossards</div>);
  if (!bibs_list || isErrorBibs) return (<div>Erreur chargement des dossards</div>);

  if (!dancer_list) return (<div>Chargement liste danseurs</div>)

  //const url = `/events/${loaderData.id_event}/competitions/${loaderData.id_competition}`;
  const url = "";

  return (
    <>
      <h1>Compétition {competition?.name}</h1>
      <p>Type : {competition?.kind}</p>
      <p>Catégorie : {competition?.category}</p>
      {!isAdmin &&
        <>
          <h2>Dossards</h2>
          <PublicBibList bib_list={bibs_list.bibs.filter((b) => b.target.target_type === "single")} />
        </>
      }

      {isAdmin &&
        <>
          <h1>Compétition {competition?.name}</h1>
          <CompetitionNavigation url={url} />
          <p>Type : {competition?.kind}</p>
          <p>Catégorie : {competition?.category}</p>
          <PhaseList id_competition={id_competition} competition_data={competition as Competition} phase_list={phase_list as PhaseIdList} />
          <NewPhaseFormComponent id_competition={id_competition} />
          <BibListComponent id_competition={id_competition} />
          <NewBibFormComponent id_competition={id_competition} bibs_list={bibs_list} dancer_list={dancer_list} />
        </>
      }

    </>
  );
}

export function CompetitionResults({ id_competition, results_data, promotions_data }: { id_competition: CompetitionId, results_data: DancerCompetitionResultsList, promotions_data: PromotionList }) {

  const same_comp_dancer_role = (dcr: DancerCompetitionResults, p: Promotion) =>
    dcr.competition === p.competition && dcr.dancer === p.dancer && dcr.role[0] === p.role[0];

  const queryClient = useQueryClient();
  const { mutate: updateCompetition, isError, error, isSuccess } = usePutApiCompIdPromotions({
    mutation: {
      onSuccess: () => {
        queryClient.invalidateQueries({
          queryKey: getGetApiCompIdPromotionsQueryKey(id_competition),
        });
        queryClient.invalidateQueries({
          queryKey: getGetApiCompIdResultsQueryKey(id_competition),
        });
      },
      onError: (err) => {
        console.error('Error updating competition:', err);
      }
    }
  });

  return (
    <>

      <button type="button" onClick={() => updateCompetition({ id: id_competition, data: undefined })}>Calculer les promotions</button>
      {isError && <div className="error_message">⚠️ {error.message}</div>}
      {isSuccess && <div>Promotions réussies</div>}
      <h1>Resultats compétition</h1>
      <table>
        <tbody>
          <tr>
            <th>Dancer</th>
            <th>Role</th>
            <th>Rang</th>
            <th>Points</th>
            <th>Ancienne division</th>
            <th>Promotion à ?</th>
          </tr>
          {results_data.results.sort((a, b) => b.points - a.points).map((dcr, index) => (
            <tr key={index}>
              <td>
                <DancerCell id_dancer={dcr.dancer} />
              </td>
              <td>{dcr.role}</td>
              <td>{get_rang(dcr.result)}</td>
              <td>{dcr.points}</td>
              <td>
                {promotions_data.promotions?.find(p => same_comp_dancer_role(dcr, p)) &&
                  <Badge role={dcr.role.toString()} divisions={promotions_data.promotions?.find(p => same_comp_dancer_role(dcr, p))?.current_divisions as Divisions} />
                }
              </td>
              <td>
                {promotions_data.promotions?.find(p => same_comp_dancer_role(dcr, p)) &&
                  <Badge role={dcr.role.toString()} divisions={promotions_data.promotions?.find(p => same_comp_dancer_role(dcr, p))?.new_divisions as Divisions} />
                }
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
}
