import { Outlet } from "react-router";

export default function ArtefactHome() {

    return (
        <Outlet />
    );
}

export const handle = {
  breadcrumb: () => "Artefacts"
};
