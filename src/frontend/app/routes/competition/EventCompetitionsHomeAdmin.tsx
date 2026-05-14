
import type { Route } from "./+types/EventCompetitionsHomeAdmin"

import React from 'react';
import { type DehydratedState, QueryClient, dehydrate } from "@tanstack/react-query";
import { NavLink, Outlet, type UIMatch } from "react-router";

import { getGetApiEventIdCompsQueryOptions, getGetApiEventIdQueryOptions } from "~/hookgen/event/event";
import type { CompetitionIdList, EventId } from "~/hookgen/model";

type loaderDataType = {
  dehydratedState: DehydratedState,
  competitionIdList: CompetitionIdList
};

export async function loader({ params }: Route.LoaderArgs) {

  const queryClient = new QueryClient();
  const id_event = Number(params.id_event) as EventId;

  await queryClient.prefetchQuery(getGetApiEventIdQueryOptions(id_event));

  const competitionIdList = await queryClient.fetchQuery(getGetApiEventIdCompsQueryOptions(id_event));

  return { dehydratedState: dehydrate(queryClient), competitionIdList: competitionIdList };
}


export default function EventCompetitionsHomeAdmin({ }: Route.ComponentProps) {
  return (<Outlet />);
}


export const handle = {
  breadcrumb: (match: UIMatch<loaderDataType, unknown>) =>
    <div className="main-nav">
      <span>
        <NavLink to={match.pathname}>Competitions</NavLink>
      </span>
      <div className="sub-nav">
        <ol>
          {match?.loaderData?.competitionIdList.competitions.map((compId) => (
            <li>
              <NavLink to={`${match.pathname}/${compId}`}>
              Competition {compId}
              </NavLink>
            </li>
          ))
          }
        </ol>
      </div>
    </div>
};