import type { Route } from "./+types/EventDetailsHome"
import "~/styles/ContentStyle.css";

import React from 'react';
import { getApiEventId } from '@hookgen/event/event';

import { type EventId } from "@hookgen/model";
import { Outlet } from "react-router";

export async function loader({ params }: Route.LoaderArgs) {

    let id_event_number = Number(params.id_event) as EventId;
    const event_data = await getApiEventId(id_event_number);
    return {
        id_event: id_event_number,
        event_data,
    };
}

export default function EventDetailsHome({ }: Route.ComponentProps) {

    return (<Outlet />);
}
