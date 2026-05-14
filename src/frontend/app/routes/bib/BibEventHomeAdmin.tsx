
import React from 'react';
import { Link, NavLink, Outlet, type UIMatch } from "react-router";


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
  breadcrumb: (match: UIMatch) =>
    <div className="main-nav">
      <span>
        <NavLink to={match.pathname}>Bibs</NavLink>
      </span>
    </div>
};
