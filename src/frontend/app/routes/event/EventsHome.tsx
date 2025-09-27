import type { Route } from "./+types/EventsHome";

import { Outlet } from "react-router";
import { getApiEvents } from "@hookgen/event/event";
import type { EventIdList } from "@hookgen/model";
import Breadcrumbs from "@routes/header/breadcrumbs";
import { authMiddleware } from "~/auth.server";


type loaderProps = Promise<{
    event_list: EventIdList;
}>


export const middleware: Route.MiddlewareFunction[] = [
  authMiddleware,
];


export async function loader({ params }: Route.LoaderArgs) : loaderProps {

    const event_list = await getApiEvents();
    return {
        event_list,
    };
}


export default function EventsHome({
    loaderData,
}: Route.ComponentProps) {

    return (
        <>
            <Breadcrumbs />
            <div className="content-container">
                <Outlet />
            </div>
        </>
    );
}

export const handle = {
  breadcrumb: () => "Events"
};
