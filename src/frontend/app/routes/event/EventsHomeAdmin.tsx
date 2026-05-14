import type { Route } from "./+types/EventsHomeAdmin";

import { NavLink, Outlet, type UIMatch } from "react-router";
import { dehydrate, QueryClient, type DehydratedState } from "@tanstack/react-query";
import type { EventIdList } from "~/hookgen/model";
import { getGetApiEventsQueryOptions } from "~/hookgen/event/event";

type loaderDataType = {
  dehydratedState: DehydratedState,
  eventIdList: EventIdList
};

export async function loader({ params }: Route.LoaderArgs) {

  const queryClient = new QueryClient();

  await queryClient.prefetchQuery(getGetApiEventsQueryOptions());

  const eventIdList = await queryClient.fetchQuery(getGetApiEventsQueryOptions());

  return { dehydratedState: dehydrate(queryClient), eventIdList: eventIdList };
}

export default function EventsHomeAdmin({}: Route.ComponentProps) {

    return (
        <>
            <div className="content-container">
                <Outlet />
            </div>
        </>
    );
}




export const handle = {
  breadcrumb: (match: UIMatch<loaderDataType, unknown>) =>
    <div className="main-nav">
      <span>
        <NavLink to={match.pathname}>Events</NavLink>
      </span>
      <div className="sub-nav">
        <ol>
          {match?.loaderData?.eventIdList.events.map((eventId) => (
            <li>
              <NavLink to={`${match.pathname}/${eventId}`}>
              Event {eventId}
              </NavLink>
            </li>
          ))
          }
        </ol>
      </div>
    </div>
};