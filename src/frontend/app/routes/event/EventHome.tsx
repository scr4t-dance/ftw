import PageTitle from "@routes/index/PageTitle";
import { Outlet } from "react-router";

function EventHome() {

    return (
        <>
            <PageTitle title="Evénements" />
            <div className="content-container">

                <Outlet />
            </div>
        </>
    );
}

export default EventHome;