import { Outlet } from "react-router";

export default function PhasesHome() {

    return (
        <Outlet />
    );
}

export const handle = {
  breadcrumb: () => "Phases"
};
