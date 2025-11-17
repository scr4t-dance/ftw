import PageTitle from "@routes/index/PageTitle";
import { Outlet } from "react-router";

function DancerHome() {

    return (
        <>
            <PageTitle title="Compétiteurices" />
            <div className="content-container">
                <Outlet />
            </div>
        </>
    );
}

export default DancerHome;

export const handle = {
  breadcrumb: () => "Dancers"
};
