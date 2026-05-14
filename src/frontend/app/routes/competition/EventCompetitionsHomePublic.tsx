import type { Route } from "./+types/EventCompetitionsHomePublic"

import React from 'react';
import { getApiEventId } from '@hookgen/event/event';

import { type EventId } from "@hookgen/model";
import { NavLink, Outlet, type UIMatch } from "react-router";

// export async function loader({ params }: Route.LoaderArgs) {
//     let id_event_number = Number(params.id_event) as EventId;
//     const event_data = await getApiEventId(id_event_number);
//     return {
//         id_event: id_event_number,
//         event_data,
//     };
// }

export default function EventCompetitionsHome({ }: Route.ComponentProps) {

    return (<Outlet />);
}

export const handle = {
  breadcrumb: (match: UIMatch) =>
    <div className="main-nav">
      <span>
        <NavLink to={match.pathname}>Competition</NavLink>
      </span>
    </div>
};
