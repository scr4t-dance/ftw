import PageTitle from "@routes/index/PageTitle";
import { Outlet } from "react-router";
import Breadcrumbs from "../header/breadcrumbs";

function CompetitionHome() {

    return (
        <>
            <PageTitle title="Compétiteurices" />
            <Breadcrumbs />
            <div className="content-container">
                <Outlet />
            </div>
        </>
    );
}

export default CompetitionHome;

export const handle = {
  breadcrumb: () => "Dancers"
};
