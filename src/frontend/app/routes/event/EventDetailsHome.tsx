import type { Route } from "./+types/EventDetailsHome"

import React from 'react';
import { Outlet } from "react-router";

import { getApiEventId } from '@hookgen/event/event';

import { type EventId } from "@hookgen/model";

export async function loader({ params }: Route.LoaderArgs) {

    let id_event = Number(params.id_event) as EventId;
    const event_data = await getApiEventId(id_event);
    return {
        id_event,
        event_data,
    };
}

export default function EventDetailsHome({ }: Route.ComponentProps) {

    return (<Outlet />);
}

export const handle = {
  breadcrumb: () => "Event"
};
