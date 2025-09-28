import type { Route } from "./+types/EventsHome";

import { Outlet } from "react-router";
import { getApiEvents } from "@hookgen/event/event";
import type { EventIdList } from "@hookgen/model";


export type loaderProps = Promise<{
    event_list: EventIdList;
}>

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
            <div className="content-container">
                <Outlet />
            </div>
        </>
    );
}

export const handle = {
  breadcrumb: () => "Events"
};
