import PageTitle from "@routes/index/PageTitle";
import { Outlet } from "react-router";

function DancerHomePublic() {

    return (
        <>
            <PageTitle title="Compétiteurices" />
            <div className="content-container">
                <Outlet />
            </div>
        </>
    );
}

export default DancerHomePublic;
