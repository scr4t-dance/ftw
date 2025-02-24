import "../styles/ContentStyle.css"

import Header from "./Header"

function Accueil() {
    return (
        <div>
            <Header />
            <div className="content-container">
                <h1>SCR4T - Système Compétitif de Rock 4 Temps</h1>
                <h2>Présentation</h2>
                <h2>Pourquoi un système de divisions à points ?</h2>
                <h2>Changements au 1er Janvier 2025</h2>
                <h2>Nos engagements</h2>
                <h2>Contact</h2>
            </div>
        </div>
    );
}

export default Accueil;