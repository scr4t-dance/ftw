import { NavLink, Outlet, type UIMatch } from "react-router";

export default function ArtefactHome() {

  return (
    <Outlet />
  );
}

export const handle = {
  breadcrumb: (match: UIMatch) =>
    <span className="main-nav">
      <span>
        <NavLink to={match.pathname}>Artefacts</NavLink>
      </span>
    </span>
};
