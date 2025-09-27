import type { Route } from "./+types/EventDetailsHomeAdmin"

import React from 'react';
import { Outlet } from "react-router";

export default function EventDetailsHomeAdmin({ }: Route.ComponentProps) {

    return (<Outlet />);
}

export const handle = {
  breadcrumb: () => "Event"
};