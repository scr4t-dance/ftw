import type { Route } from "./+types/EventCompetitionsHomeAdmin"

import React from 'react';
import { Outlet } from "react-router";


export default function EventCompetitionsHomeAdmin({ }: Route.ComponentProps) {
    return (<Outlet />);
}

export const handle = {
  breadcrumb: () => "Competitions"
};
