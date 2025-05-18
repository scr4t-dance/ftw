import "~/styles/ContentStyle.css";

import PageTitle from "@routes/index/PageTitle";
import Header from "@routes/header/header";
import Footer from "@routes/footer/footer";
import { Outlet } from "react-router";

function CompetitionHome() {

    return (
        <>
            <PageTitle title="Phase" />
            <Header />
            <div className="content-container">

                <Outlet />
            </div>
            <Footer />
        </>
    );
}

export default CompetitionHome;