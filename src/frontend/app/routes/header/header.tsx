import { Link, useLocation, type LoaderFunctionArgs } from "react-router";
import "./Header.css";
import logo from "~/assets/logo.png";

export default function Header({ userId }: { userId: string | null }) {

    const disable_admin = import.meta.env.VITE_DISABLE_ADMIN === "true";
    const location = useLocation();
    let params = new URLSearchParams();
    params.set("from", location.pathname);

    return (
        <header>
            <div className="logo">
                <Link to="/">
                    <img src={logo} alt="Logo" />
                </Link>
            </div>

            <nav>
                <ul>
                    <li><Link to="/">Page d'accueil</Link></li>
                    <li><Link to="/events">Événements</Link></li>
                    <li><Link to="/dancers">Compétiteurs</Link></li>
                    <li><Link to="/rules">Règles</Link></li>
                    <li><Link to="/faq">FAQ</Link></li>
                    <li><Link to="/about">À propos</Link></li>
                    {!disable_admin && userId &&
                        <>
                            <li><Link to="/admin">Admin</Link></li>
                            <li><Link to={"/logout?" + params.toString()}>Log Out</Link></li>
                        </>
                    }
                    {!disable_admin && !userId &&
                        <li><Link to={"/login?" + params.toString()}>LogIn</Link></li>
                    }
                </ul>
            </nav>

            <div className="contact-button">
                <a href="mailto:scr4t.danse@gmail.com" className="header-btn">Nous contacter</a>
            </div>
        </header>
    );
}