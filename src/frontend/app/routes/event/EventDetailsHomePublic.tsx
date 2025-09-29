import type { Route } from "./+types/EventDetailsHomePublic"

import React from 'react';
import { Outlet } from "react-router";

export default function EventDetailsHome({ }: Route.ComponentProps) {

    return (<Outlet />);
}

export const handle = {
  breadcrumb: () => "Event"
};