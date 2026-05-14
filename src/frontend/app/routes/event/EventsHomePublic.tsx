import type { Route } from "./+types/EventsHomePublic";

import { NavLink, Outlet, type UIMatch } from "react-router";

export default function EventsHome({}: Route.ComponentProps) {

    return (
        <>
            <div className="content-container">
                <Outlet />
            </div>
        </>
    );
}

export const handle = {
  breadcrumb: (match: UIMatch) =>
    <div className="main-nav">
      <span>
        <NavLink to={match.pathname}>Event</NavLink>
      </span>
    </div>
};
