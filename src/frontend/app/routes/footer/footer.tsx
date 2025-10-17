import "./Footer.css";
import { Link, useLocation, type LoaderFunctionArgs } from "react-router";

export default function Footer({ userId }: { userId: string | null }) {

    const location = useLocation();
    let params = new URLSearchParams();
    params.set("from", location.pathname);

    const disable_admin = import.meta.env.VITE_DISABLE_ADMIN === "true";

    return (
        <footer>
            {!disable_admin && userId &&
                <div className="footer_buttons">
                    <div className="footer_button"><Link to="/admin">Admin</Link></div>
                    <div className="footer_button"><Link to={"/logout?" + params.toString()}>Déconnexion</Link></div>
                </div>
            }
            {!disable_admin && !userId &&
                <div className="footer_button"><Link to={"/login?" + params.toString()}>Se connecter</Link></div>
            }

            <span>© 2025 SCR4T</span>
        </footer>
    );
}
