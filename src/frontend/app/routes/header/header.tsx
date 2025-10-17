import { Link, useLocation } from "react-router";
import "./Header.css";
import logo from "~/assets/logo.png";

export default function Header() {

    const location = useLocation();
    let params = new URLSearchParams();
    params.set("from", location.pathname);

    return (
        <header>
            <div className="header-top">
                <div className="logo">
                    <Link to="/">
                        <img src={logo} alt="Logo" />
                    </Link>
                </div>

                <nav>
                    <ul>
                        <li><Link to="/">Accueil</Link></li>
                        <li><Link to="/events">Événements</Link></li>
                        <li><Link to="/dancers">Compétiteurs</Link></li>
                        <li><Link to="/rules">Règles</Link></li>
                        <li><Link to="/faq">FAQ</Link></li>
                        <li><Link to="/about">À propos</Link></li>
                    </ul>
                </nav>

                <div className="contact-button">
                    <a href="mailto:scr4t.danse@gmail.com" className="btn">Nous contacter</a>
                </div>
            </div>
        </header>
    );
}