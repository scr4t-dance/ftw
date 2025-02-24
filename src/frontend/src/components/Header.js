import "../styles/Header.css";
import logo from "../assets/logo.png";

function Header() {
    return (
        <header>
            <div className="logo">
                <img src={logo} alt="Logo" />
            </div>

            <nav>
                <ul>
                    <li><a href="#">Page d'accueil</a></li>
                    <li><a href="#">Événements</a></li>
                    <li><a href="#">Compétiteurs</a></li>
                    <li><a href="#">Règles</a></li>
                    <li><a href="#">FAQ</a></li>
                    <li><a href="#">À propos</a></li>
                </ul>
            </nav>

            <div className="contact-button">
                <a href="#" className="btn">Nous contacter</a>
            </div>
        </header>
    );
}

export default Header;