import type { Route } from "./+types/HomeAdmin";

import { Outlet } from "react-router";

import { authMiddleware } from "~/auth.server";

import Breadcrumbs from "@routes/header/breadcrumbs";


export const middleware: Route.MiddlewareFunction[] = [
  authMiddleware,
];


export default function EventsHomeAdmin({
    loaderData,
}: Route.ComponentProps) {

    return (
        <>
            <Breadcrumbs />
            <h1>Mode Admin</h1>
            <Outlet />
        </>
    );
}


export const handle = {
  breadcrumb: () => "Admin"
};