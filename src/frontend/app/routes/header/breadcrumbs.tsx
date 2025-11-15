import { Link, useMatches } from "react-router";

export default function Breadcrumbs() {

    const matches = useMatches();

    const crumbs = matches
        .filter((match) => match.handle?.breadcrumb)
        .map((match) => {
            const crumb =
                typeof match.handle.breadcrumb === "function"
                    ? match.handle.breadcrumb(match.params)
                    : match.handle.breadcrumb;

            return { id: match.id, pathname: match.pathname, crumb };
        });

    return (
        <>
            <nav className="breadcrumbs no-print">
                {crumbs.map((c, i) => (
                    <span key={c.id}>
                        <Link to={c.pathname}>{c.crumb}</Link>
                        {i < crumbs.length - 1 && " / "}
                    </span>
                ))}
            </nav>
        </>
    );
}