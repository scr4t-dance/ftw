import { dehydrate, QueryClient, type DehydratedState } from "@tanstack/react-query";
import { NavLink, Outlet, type UIMatch } from "react-router";
import type { Route } from "./+types/PhaseHome";
import type { CompetitionId, EventId, PhaseId, PhaseIdList } from "~/hookgen/model";
import { getGetApiEventIdQueryOptions } from "~/hookgen/event/event";
import { getGetApiCompIdQueryOptions } from "~/hookgen/competition/competition";
import { getGetApiCompIdPhasesQueryOptions } from "~/hookgen/phase/phase";

type loaderDataType = {
  dehydratedState: DehydratedState,
  phaseList: PhaseIdList
};

export async function loader({ params }: Route.LoaderArgs) {

  const queryClient = new QueryClient();
  const id_event = Number(params.id_event) as EventId;
  const id_competition = Number(params.id_competition) as CompetitionId;

  await queryClient.prefetchQuery(getGetApiEventIdQueryOptions(id_event));
  await queryClient.prefetchQuery(getGetApiCompIdQueryOptions(id_competition));
  await queryClient.prefetchQuery(getGetApiCompIdPhasesQueryOptions(id_competition));

  const phaseList = await queryClient.fetchQuery(getGetApiCompIdPhasesQueryOptions(id_competition));

  return { dehydratedState: dehydrate(queryClient), phaseList: phaseList };
}

export default function PhasesHome() {

  return (
    <Outlet />
  );
}

export const handle = {
  breadcrumb: (match: UIMatch<loaderDataType, unknown>) =>
    <div className="main-nav">
      <span>
        <NavLink to={match.pathname}>Phases</NavLink>
      </span>
      <div className="sub-nav">
        <ol>
          {match?.loaderData?.phaseList.phases.map((phaseId) => (
            <li>
              <NavLink to={`${match.pathname}/${phaseId}`}>
              Phase {phaseId}
              </NavLink>
            </li>
          ))
          }
        </ol>
      </div>
    </div>
};