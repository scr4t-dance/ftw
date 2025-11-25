import type { Route } from "./+types/EventsHomeAdmin";

import { Outlet } from "react-router";

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
  breadcrumb: () => "Events"
};