import type { Route } from "./+types/CompetitionHomeAdmin"

import React from 'react';
import { Outlet } from "react-router";


export default function CompetitionHome({ }: Route.ComponentProps) {

    return (<Outlet />);
}

export const handle = {
  breadcrumb: () => "Competition"
};
