import PageTitle from "@routes/index/PageTitle";
import { Outlet } from "react-router";

function CompetitionHome() {

    return (
        <>
            <PageTitle title="Compétiteurices" />
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
