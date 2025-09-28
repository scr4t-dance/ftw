import "~/styles/ContentStyle.css"
import logo from "~/assets/logo.png";

import PageTitle from "./PageTitle";
import Header from "@routes/header/header";
import Footer from "@routes/footer/footer";


export function HomePage() {
    return (
        <>
            <PageTitle title="SCR4T" />
            <Header />
            <div className="content-container">
                <div>
                    <img src={logo} id="homepage-logo" alt="Logo" />

                    <h1>SCR4T - Système Compétitif de Rock 4 Temps</h1>

                    <h2>Présentation</h2>
                    <p>
                        Le SCR4T, ou "Scrat" pour les amis et les fans de "l'Âge de Glace", est le "Système Compétitif de Rock 4 Temps".
                        C'est un système d'organisation de compétition pensé pour, et amené à évoluer avec la communauté de Rock 4 Temps
                        (ou toute autre appellation de danses de couple se considérant comme voisine de celle-ci) d'Île de France.
                    </p>
                    <p>Le SCR4T propose une architecture de compétition en 3 sous-systèmes complémentaires :</p>
                    <ul>
                        <li>Une organisation en divisions pour les danseur•euse•s, stable dans le temps et partagée par plusieurs compétitions ;</li>
                        <li>Une architecture de compétition prélims/demi-finales/finales, dont l'objectif est de rendre comparables les différentes compétitions entre elles ;</li>
                        <li>Un système de points, régulant le passage d'une division à une autre.</li>
                    </ul>
                </div>

                <h2>Pourquoi un système de divisions à points ?</h2>
                <p>Avec les années, la communauté de Rock 4 Temps grandit, et nous en sommes très heureux. Avec cette croissance, les écarts de niveau entre les débutant•e•s et les danseur•euse•s les plus aguerri•e•s croissent également.</p>
                <p>Nous proposons un système de divisions à points pour faire de la compétition un parcours, qui puisse être motivant et épanouissant pour tout le monde, pour accompagner l'évolution d'un danseur-euse de Rock 4 Temps sur plusieurs paliers.</p>
                <p>
                    Chaque danseur·euse débutant dans les compétitions SCR4T commence dans la première division : la division Initié.
                    Iel y reste jusqu'à avoir obtenu suffisamment de succès compétitifs, pour lui ouvrir l'accès à la compétition dans la division suivante : la division Intermédiaire.
                    Iel accumule alors des points Intermédiaire, qui lui permettent d'obtenir l'accès à la division suivante : la division Avancé.
                </p>

                <h2>Changements au 1er Janvier 2025</h2>
                <ul>
                    <li>Création d'une division Avancé et définition des conditions d'accès à cette division. <a href="/rules#divisions">En savoir plus</a>.</li>
                    <li>Ajustement des points gagnés par les demi-finalistes. <a href="/rules#points">En savoir plus</a>.</li>
                    <li>Changement du fonctionnement des dérogations pour participer à une division pour laquelle on ne remplit pas les conditions d'inscriptions. <a href="/rules#petition">En savoir plus</a>.</li>
                </ul>

                <h2>Changements au 9 Juillet 2025</h2>
                <ul>
                    <li>Augmentation des barres d'accès de chaque division : il faudra à présent 15 points initiés pour pouvoir accéder à la division intermédiaire et 30 points intermédiaires pour pouvoir accéder à la division avancé. <a href="/rules#divisions">En savoir plus</a>.</li>
                    <li>Ajout d'un 6ème tier de compétition au-delà de 65 compétiteurs dans un rôle. <a href="/rules#phases">En savoir plus</a>.</li>
                    <li>Légère révision à la baisse de la grille des point obtenus selon le classement. <a href="/rules#points">En savoir plus</a>.</li>
                </ul>
                <div className="nb nb-warning">
                    La réforme n'est pas rétroactive, les accès gagnés aux divisions avant le 9 juillet 2025 sont conservés.
                </div><br />

                <h2>Nos engagements</h2>
                <ul>
                    <li>Rendre accessible via internet les règles permettant de passer d'une division à une autre, pour tous les compétiteur·ice·s</li>
                    <li>Assurer la disponibilité du nombre de points détenus par les compétiteur·ice·s et sa mise à jour</li>
                    <li>Tenir disponible la liste des compétiteur·ice·s par division, pour les compétitions souhaitant adopter le système</li>
                    <li>Tenir à jour la liste des compétitions reposant sur le SCR4T</li>
                    <li>Proposer gratuitement aux organisateurs·trices de compétitions une aide pour gérer la notation et le classement des compétiteur·ice·s pendant la compétition</li>
                    <li>Un fonctionnement et des logiciels libres et open-source</li>
                </ul>

                <h2>Contact</h2>
                <p>Pour ne pas rater les nouvelles infos, suivez <a target="_blank" href="https://www.facebook.com/SCR4T.danse">notre page facebook</a> !</p>
                <p>Vous êtes un•e organisateur•ice souhaitant utiliser le système, un•e compétiteur•ice curieux•se ? Contactez-nous à : <a href="mailto:scr4t.danse@gmail.com">scr4t.danse@gmail.com</a>.</p>
            </div>
            <Footer />
        </>
    );
}
