
import React from 'react';
import { Link, NavLink, Outlet, type UIMatch } from "react-router";


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
  breadcrumb: (match: UIMatch) =>
    <div className="main-nav">
      <span>
        <NavLink to={match.pathname}>Bibs</NavLink>
      </span>
    </div>
};
