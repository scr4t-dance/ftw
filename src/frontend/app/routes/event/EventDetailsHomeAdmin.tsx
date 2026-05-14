import type { Route } from "./+types/EventDetailsHomeAdmin"

import React from 'react';
import { NavLink, Outlet, type UIMatch } from "react-router";

export default function EventDetailsHomeAdmin({ }: Route.ComponentProps) {

  return (<Outlet />);
}

export const handle = {
  breadcrumb: (match: UIMatch) =>
    <div className="main-nav">
      <span>
        <NavLink to={match.pathname}>Event</NavLink>
      </span>

      <div className="sub-nav">
        <ol>
          <li>
            <NavLink to={`${match.pathname}/competitions`}>
              Liste des competitions
            </NavLink>
          </li>
          <li>
            <NavLink to={`${match.pathname}/competitions/new`}>
              Créer une competition
            </NavLink>
          </li>
          <li>
            <NavLink to={`${match.pathname}/bibs`}>
              Gestion des dossards de toutes les compétitions
            </NavLink>
          </li>
        </ol>
      </div>
    </div>
};