import "~/styles/ContentStyle.css";

import PageTitle from "@routes/index/PageTitle";
import Header from "@routes/header/header";
import Footer from "@routes/footer/footer";
import { Outlet } from "react-router";

function EventHome() {

    return (
        <>
            <div className="no-print">
                <PageTitle title="Evénements" />
                <Header />
            </div>
            <div className="content-container">

                <Outlet />
            </div>
            <div className="no-print">
                <Footer />
            </div>
        </>
    );
}

export default EventHome;