import type { Route } from "./+types/EventsHomeAdmin";

import { Outlet } from "react-router";

import {type loaderProps} from "@routes/event/EventsHome";
import Breadcrumbs from "@routes/header/breadcrumbs";
import { getApiEvents } from "@hookgen/event/event";


export async function loader({ params }: Route.LoaderArgs) : loaderProps {

    const event_list = await getApiEvents();
    return {
        event_list,
    };
}

export default function EventsHomeAdmin({
    loaderData,
}: Route.ComponentProps) {

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