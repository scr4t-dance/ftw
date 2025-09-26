import "~/styles/ContentStyle.css";

import PageTitle from "@routes/index/PageTitle";
import Header from "@routes/header/header";
import Footer from "@routes/footer/footer";
import { Outlet } from "react-router";
import Breadcrumbs from "../header/breadcrumbs";

function CompetitionHome() {

    return (
        <>
            <PageTitle title="Compétiteurices" />
            <Header />
            <Breadcrumbs />
            <div className="content-container">

                <Outlet />
            </div>
            <Footer />
        </>
    );
}

export default CompetitionHome;

export const handle = {
  breadcrumb: () => "Dancers"
};
