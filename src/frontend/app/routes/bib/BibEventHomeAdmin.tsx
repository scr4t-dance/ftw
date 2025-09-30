
import React from 'react';
import { Link, Outlet } from "react-router";


import type { Route } from './+types/BibEventHomeAdmin';

function BibEventHomeAdmin({}: Route.ComponentProps) {

    return (
        <>
            <Outlet />
        </>
    );
}

export default BibEventHomeAdmin;

export const handle = {
  breadcrumb: () => "Bibs"
};
