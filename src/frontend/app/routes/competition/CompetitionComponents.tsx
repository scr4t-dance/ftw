
import React from 'react';
import { Link, useLocation } from "react-router";
import { useQueries, useQueryClient } from "@tanstack/react-query";

import { getGetApiCompIdQueryOptions, useGetApiCompId, usePutApiCompIdForbiddenPairs } from '@hookgen/competition/competition';
import { useGetApiEventIdComps } from "@hookgen/event/event";
import { type BibList, type CouplesHeat, type DancerId } from "@hookgen/model";
import { BibListComponent, PublicBibList } from '../bib/BibComponents';
import { useGetApiCompIdBibs } from '~/hookgen/bib/bib';
import { NewBibFormComponent } from '../bib/NewBibFormComponent';
import { getGetApiCompIdForbiddenPairsQueryKey, useGetApiCompIdForbiddenPairs, useGetApiCompIdPhases } from '~/hookgen/phase/phase';
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
import { Field } from '../index/field';
import { Controller, get, useFieldArray, useForm, type SubmitHandler } from 'react-hook-form';

export function CompetitionTable({ competition_id_list, competition_data_list }: { competition_id_list: CompetitionIdList, competition_data_list: Competition[] }) {

  const location = useLocation();
  const url = location.pathname.includes("competition") ? "" : "competitions/";

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
      <p>
        <Link to={`${url}forbidden`}>
          Formulaire paires interdites en poules solo
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
          <h2>Formulaire de nouvelle phase</h2>
          <NewPhaseFormComponent id_competition={id_competition} />
          <h2>Liste des dossards</h2>
          <BibListComponent id_competition={id_competition} />
          <h2>Formulaire nouveau dossard</h2>
          <NewBibFormComponent id_competition={id_competition} bibs_list={bibs_list} dancer_list={dancer_list} />
          <h2>Paires interdites en poules solo</h2>
          <p>
            <Link to={`${url}forbidden`}>
              Formulaire paires interdites en poules solo
            </Link>
          </p>
          <ForbiddenCouplesTable id_competition={id_competition} />
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

export function ForbiddenCouplesTable({ id_competition }: { id_competition: CompetitionId }) {

  const { data: forbidden_pairs, isLoading, isError } = useGetApiCompIdForbiddenPairs(id_competition);

  if (isLoading) return (<div>Chargement de la competition</div>);
  if (isError) return (<div>Erreur chargement de la competition</div>);

  return (
    <table>
      <tbody>
        <tr>
          <td>Dancer 1</td>
          <td>Dancer 2</td>
        </tr>
        {forbidden_pairs?.couples.map((c) => (
          <tr key={`${c.leader}-${c.follower}`}>
            <td>
              <DancerCell id_dancer={c.leader} />
            </td>
            <td>
              <DancerCell id_dancer={c.follower} />
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  )

}

type ForbiddenCouplesFormProps = {
  id_competition: CompetitionId,
  forbidden_pairs: CouplesHeat,
  leaders: DancerId[],
  followers: DancerId[],
}

export function ForbiddenCouplesForm({ id_competition, forbidden_pairs, leaders, followers }: ForbiddenCouplesFormProps) {

  const queryClient = useQueryClient();
  const { mutate: setForbiddenPairs, isError, error, isSuccess } = usePutApiCompIdForbiddenPairs({
    mutation: {
      onSuccess: (_, { data }) => {
        queryClient.invalidateQueries({
          queryKey: getGetApiCompIdForbiddenPairsQueryKey(id_competition),
        });
        reset(data);
      },
      onError: (err) => {
        console.error('Error updating competition:', err);
      }
    }
  });

  const {
    register,
    control,
    reset,
    handleSubmit,
    formState: { errors, defaultValues, isSubmitSuccessful, isSubmitting },
  } = useForm<CouplesHeat>({
    defaultValues: forbidden_pairs,
  });


  const { fields, append, remove } = useFieldArray({
    control: control,
    name: `couples`,
  });

  const onSubmit: SubmitHandler<CouplesHeat> = (data) => {
    console.log({ id: id_competition, data: data });
    setForbiddenPairs({ id: id_competition, data: data });
  };

  return (
    <>
      <form onSubmit={handleSubmit(onSubmit)}>
        <table>
          <thead>
            <tr>
              <th>Compétiteurice A</th>
              <th>Compétiteurice B</th>
              <th className='no-print'>Action</th>
            </tr>
          </thead>
          <tbody>
            {fields && fields.map((key, index) => (
              <tr key={key.id}>
                <input type="hidden" {...register(`couples.${index}.target_type`)} />
                <td>
                  <Field label="" error={get(errors, `couples.${index}.leader`)}>
                    <Controller
                      control={control}
                      name={`couples.${index}.leader`}
                      render={({ field }) => (
                        <select
                          onChange={(e) => {
                            const d = Number(e.target.value);
                            if (d === -1) {
                              field.onChange({
                                ...e,
                                target: {
                                  ...e.target,
                                  value: defaultValues?.couples?.[index]?.leader as DancerId
                                }
                              });
                              return;
                            }
                            const selected = {
                              ...e,
                              target: {
                                ...e.target,
                                value: d
                              }
                            };
                            field.onChange(selected);
                          }}
                        >
                          {[defaultValues?.couples?.[index]?.leader as DancerId].concat(leaders).map((id_dancer) => (
                            <option key={id_dancer} value={id_dancer}>
                              <DancerCell id_dancer={id_dancer} />
                            </option>
                          ))}
                        </select>
                      )}
                    />
                  </Field>
                </td>
                <td>
                  <Field label="" error={get(errors, `couples.${index}.follower`)}>
                    <Controller
                      control={control}
                      name={`couples.${index}.follower`}
                      render={({ field }) => (
                        <select
                          onChange={(e) => {
                            const d = Number(e.target.value);
                            if (d === -1) {
                              field.onChange({
                                ...e,
                                target: {
                                  ...e.target,
                                  value: defaultValues?.couples?.[index]?.follower as DancerId
                                }
                              });
                              return;
                            }
                            const selected = {
                              ...e,
                              target: {
                                ...e.target,
                                value: d
                              }
                            };
                            field.onChange(selected);
                          }}
                        >
                          {[defaultValues?.couples?.[index]?.follower as DancerId].concat(followers).map((id_dancer) => (
                            <option key={id_dancer} value={id_dancer}>
                              <DancerCell id_dancer={id_dancer} />
                            </option>
                          ))}
                        </select>
                      )}
                    />
                  </Field>
                </td>
                <td className='no-print'>
                  <button type="button" onClick={() => {
                    remove(index);
                  }}>Delete</button>

                </td>
              </tr>
            ))}
            <tr>
              <td>
                <button
                  type="button"
                  onClick={() => {
                    append({ target_type: "couple", leader: -1, follower: -1 });
                  }}
                >
                  append
                </button>
              </td>
            </tr>
          </tbody>
        </table>
        {isError &&
          <p>
            {error.message}
          </p>
        }
        {errors.root?.formValidation &&
          <p className="error_message">⚠️ {errors.root.formValidation.message}</p>
        }

        {errors.root?.serverError &&
          <p className="error_message">⚠️ {errors.root.serverError.message}</p>
        }
        <button type="submit" disabled={isSubmitting}>
          Mettre à jour la phase
        </button>
        <button type="button" disabled={isSubmitting} onClick={() => reset(forbidden_pairs)}>
          Réinitialiser
        </button>
        {isSubmitSuccessful &&
          <p>
            Formulaire envoyé avec succès.
          </p>
        }
        {isSuccess &&
          <div className="success_message">
            ✅ Paires interdites pour la compétition "{id_competition}" mis à jour avec succès.
          </div>
        }
      </form>
    </>
  );
}



export function ForbiddenCouplesFormComponent({ id_competition }: { id_competition: CompetitionId }) {

  const { data: forbidden_pairs, isLoading, isError: isErrorForbidden, isSuccess } = useGetApiCompIdForbiddenPairs(id_competition);
  const { data: dataBibs, isLoading: isLoadingBibs, isError: isErrorBibs, error: errorBibs } = useGetApiCompIdBibs(id_competition);

  if (isLoadingBibs) return <div>Chargement des compétiteur-euses...</div>;
  if (isErrorBibs) return <div>Erreur: {errorBibs.message}</div>;

  if (isLoading) return (<div>Chargement de la competition</div>);
  if (isErrorForbidden) return (<div>Erreur chargement de la competition</div>);
  if (!isSuccess) return (<div>Erreur chargement Paires Interdites</div>);

  const targets = (dataBibs as BibList).bibs.map(b => b.target).filter(t => t.target_type === "single");
  const leaders = targets.filter(t => t.role[0] === "Leader").map(t => t.target);
  const followers = targets.filter(t => t.role[0] === "Follower").map(t => t.target);

  return (
    <>
      <ForbiddenCouplesForm
        id_competition={id_competition}
        forbidden_pairs={forbidden_pairs}
        leaders={leaders}
        followers={followers}
      />
    </>
  );
}