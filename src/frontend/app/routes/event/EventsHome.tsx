import "~/styles/ContentStyle.css";

import Header from "@routes/header/header";
import Footer from "@routes/footer/footer";
import { Outlet } from "react-router";
import type { Route } from "./+types/EventsHome";
import { getApiEvents } from "~/hookgen/event/event";
import type { EventIdList } from "~/hookgen/model";

type loaderProps = Promise<{
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
            <Header />
            <div className="content-container">
                <Outlet />
            </div>
            <Footer />
        </>
    );
}
