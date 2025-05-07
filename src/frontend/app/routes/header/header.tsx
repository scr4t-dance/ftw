import "./Header.css";
import logo from "~/assets/logo.png";

export default function Header() {
    return (
        <header>
            <div className="logo">
                <a href="/">
                    <img src={logo} alt="Logo" />
                </a>
            </div>

            <nav>
                <ul>
                    <li><a href="/">Page d'accueil</a></li>
                    <li><a href="/events">Événements</a></li>
                    <li><a href="/dancer">Compétiteurs</a></li>
                    <li><a href="/rules">Règles</a></li>
                    <li><a href="/faq">FAQ</a></li>
                    <li><a href="/about">À propos</a></li>
                </ul>
            </nav>

            <div className="contact-button">
                <a href="mailto:scr4t.danse@gmail.com" className="btn">Nous contacter</a>
            </div>
        </header>
    );
}