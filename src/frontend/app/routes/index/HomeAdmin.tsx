import type { Route } from "./+types/HomeAdmin";

import { NavLink, Outlet, type UIMatch } from "react-router";

import { authMiddleware } from "~/auth.server";
import Breadcrumbs from "@routes/header/breadcrumbs";

export const middleware: Route.MiddlewareFunction[] = [
  authMiddleware,
];


export default function EventsHomeAdmin({
  loaderData,
}: Route.ComponentProps) {

  return (
    <>
      <div className="header-breadcrumbs no-print">
        <Breadcrumbs />
      </div>
      <h1 className="no-print">Mode Admin</h1>
      <Outlet />
    </>
  );
}



export const handle = {
  breadcrumb: (match: UIMatch) =>
    <div className="main-nav">
      <span>
        <NavLink to={match.pathname}>Admin</NavLink>
      </span>
      <div className="sub-nav">
        <ol>
          <li>
            <NavLink to={`${match.pathname}/events`}>
              Events
            </NavLink>
          </li>
          <li>
            <NavLink to={`${match.pathname}/dancers`}>
              Dancers
            </NavLink>
          </li>
          <li>
            <NavLink to={`${match.pathname}/events/1`}>
              Evénement en cours
            </NavLink>
          </li>
        </ol>
      </div>
    </div>
};