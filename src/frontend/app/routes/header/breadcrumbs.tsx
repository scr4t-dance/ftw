import { Link, useMatches, type UIMatch } from "react-router";


type BreadcrumbHandle = {
  breadcrumb: (match: UIMatch) => React.ReactNode;
};


export default function Breadcrumbs() {

    const matches = useMatches();

    const crumbs = matches
        .filter((match) => (match.handle as BreadcrumbHandle)?.breadcrumb,)
        .map((match) => {
            const crumb = (match.handle as BreadcrumbHandle).breadcrumb(match);

            return { id: match.id, pathname: match.pathname, crumb };
        });

    return (
        <>
            <nav className="breadcrumbs">
                {crumbs.map((c, i) => (
                    <span key={i}>
                        {c.crumb}
                        {i < crumbs.length - 1 && " / "}
                    </span>
                ))}
            </nav>
        </>
    );
}