import type { Route } from "./+types/EventDetailsHomePublic"

import React from 'react';
import { NavLink, Outlet, type UIMatch } from "react-router";

export default function EventDetailsHome({ }: Route.ComponentProps) {

    return (<Outlet />);
}

export const handle = {
  breadcrumb: (match: UIMatch) =>
    <div className="main-nav">
      <span>
        <NavLink to={match.pathname}>Event</NavLink>
      </span>
    </div>
};
