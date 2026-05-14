import type { Route } from "./+types/CompetitionHomePublic"

import React from 'react';
import { NavLink, Outlet, type UIMatch } from "react-router";


export default function CompetitionHome({ }: Route.ComponentProps) {

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
