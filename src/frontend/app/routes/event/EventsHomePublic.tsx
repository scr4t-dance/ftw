import type { Route } from "./+types/EventsHomePublic";

import { Outlet } from "react-router";

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
  breadcrumb: () => "Events"
};
