
import React from 'react';
import { Link, Outlet } from "react-router";


import type { Route } from './+types/BibHomeAdmin';

function BibHomePublic({}: Route.ComponentProps) {

    return (
        <>
            <Outlet />
        </>
    );
}

export default BibHomePublic;

export const handle = {
  breadcrumb: () => "Bibs"
};
