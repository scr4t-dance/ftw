import PageTitle from "@routes/index/PageTitle";
import { NavLink, Outlet, type UIMatch } from "react-router";

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
  breadcrumb: (match: UIMatch) =>
    <div className="main-nav">
      <span>
        <NavLink to={match.pathname}>Dancers</NavLink>
      </span>
    </div>
};
