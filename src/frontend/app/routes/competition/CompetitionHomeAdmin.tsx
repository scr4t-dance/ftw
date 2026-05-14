import type { Route } from "./+types/CompetitionHomeAdmin"

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

      <div className="sub-nav">
        <ol>
          <li>
            <NavLink to={`${match.pathname}/phases`}>
              Phases
            </NavLink>
          </li>
          <li>
            <NavLink to={`${match.pathname}/bibs`}>
              Bibs
            </NavLink>
          </li>
          <li>
            <NavLink to={`${match.pathname}/phases/new`}>
              Création Phase
            </NavLink>
          </li>
          <li>
            <NavLink to={`${match.pathname}/promotions`}>
              Résultats/Promotions
            </NavLink>
          </li>
          <li>
            <NavLink to={`${match.pathname}/forbidden`}>
              Formulaire paires interdites en poules solo
            </NavLink>
          </li>
        </ol>
      </div>
    </div>
};
