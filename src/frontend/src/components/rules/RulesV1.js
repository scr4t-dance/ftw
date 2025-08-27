import "../../styles/ContentStyle.css"

function RulesV1() {
    return (
        <>
            <div id="rules-ver-buttons-container">
                <div className="rules-ver-button btn">
                    <a href="/rules?ver=2">Règles actuelles</a>
                </div>

                <div className="rules-ver-button btn selected">
                    <a href="/rules?ver=1">Règles jusqu'au 09/07/2025</a>
                </div>

                <div className="rules-ver-button btn">
                    <a href="/rules?ver=0">Règles jusqu'au 31/12/2025</a>
                </div>
            </div>

            <div className="nb nb-warning">
                Le contenu de cette page se réfère au fonctionnement du SCR4T entre le 1er janvier 2025 et le 9 juillet 2025, et est rendu public à des fins d'archivage et de transparence uniquement.
            </div>

            <h3>Préambule</h3>
            <p>Le SCR4T propose une architecture de compétitions en trois axes :</p>
            <ol>
                <li>Les étapes de compétition ;</li>
                <li>Les divisions compétitives ;</li>
                <li>Les points permettant de passer d'une division à une autre.</li>
            </ol>
            <p>Conseils préalables à l'application des règles :</p>
            <ul>
                <li>
                    Le format de compétition concerné par l'obtention de points est uniquement le format Jack'n'Jill : partenaire et musique tirés au hasard, au moins deux fois, à chaque phase de compétition. Cela permet au SCR4T de refléter une évolution individuelle de chaque danseur•euse.
                    <br/>Cependant, les organisateur•ice•s de Strictly (compétitions par couple) ou de concours de chorégraphies peuvent demander accès à la base de données pour définir des divisions dans ces compétitions. Elles ne permettent cependant pas d'obtenir de points.
                </li>
                <li>
                    Les organisateur•ice•s de compétition doivent, dans la mesure du possible, proposer des jurys formés, diversifiés et paritaires. Nous pensons qu'un juge de danse doit pouvoir expliquer ses choix à l'aide de son expérience et de ses opinions personnelles, et doit pouvoir aiguiller les compétiteur•ice•s sur les parties positives de leurs performances ainsi que sur des pistes d'amélioration. 
                    <br/>Nous pensons que les jurys devraient, aussi souvent que possible, représenter différentes visions de la danse, car c'est une partie inhérente de notre communauté de 4 Temps. Nous pensons que les jurys devraient avoir autant de juges spécialisés dans le rôle follower que dans le rôle leader.
                </li>
                <li>
                    Nous encourageons l'usage de l'algorithme de placement relatif pour les finales. Cet algorithme permet d'attribuer le même poids aux scores de chaque juge, sans effets d'échelle. 
                    <br/>Voir cette ressource pour mieux comprendre : <a href="https://www.worldsdc.com/wp-content/uploads/2016/04/Relative_placement.pdf" target="_blank">https://www.worldsdc.com/wp-content/uploads/2016/04/Relative_placement.pdf</a>
                </li>
            </ul>
            <div className="nb">
                <p><b>NB : </b>les règles d'utilisation du SCR4T n'incluent pas un règlement ou barême “type”. Le SCR4T ne prétend pas à un droit de regard sur les critères de jugement appliqués par une compétition. Nous pouvons fournir sur demande aux compétitions qui le souhaiteraient :</p>
                <ul>
                    <li>Le règlement de certaines compétitions ayant adopté le SCR4T. Nous recommandons des barèmes évoluant avec les divisions, dans lesquels les attentes en division Initié mettent l'accent sur ce qui devrait selon nous être prioritaire lorsque l'on débute.</li>
                    <li>Une formation à l'éthique du jugement pour les juges si les organisateur-ices ou les juges la demandent.</li>
                </ul>
            </div>

            <h3 id="phases">Phases de compétition</h3>
            <p>Les compétitions adoptant le SCR4T sont organisées en phases préliminaires, demi-finales et finales.</p>
            <ul>
                <li>Le nombre minimal de personnes pour ouvrir une division est de 5 personnes participantes dans le rôle minoritaire.</li>
                <li>La tenue de demi-finales et de finales dépend du nombre de personnes participant à la compétition dans le rôle le plus représenté.</li>
                <li>Le nombre de danseurs en demi-finale et finale est déterminé par le rôle le plus représenté en phases préliminaires.</li>
            </ul>
            <div className="nb">
                <b>NB : </b>l'organisation de quarts de finale peut être demandée au SCR4T si le nombre de participants dans une division le justifie.
            </div>
            <p>Le tableau ci-dessous indique le nombre minimal de danseur•euses passant à l'étape suivante de la compétition en fonction du nombre de danseur-euses du rôle majoritaire :</p>
            <table>
                <thead>
                    <tr>
                        <th>Nombre de compétiteur•ice•s dans le rôle majoritaire</th>
                        <th>Demi-finales (nombre min. de participant•e•s par rôle)</th>
                        <th>Finales (nombre min. de participant•e•s par rôle)</th>
                    </tr>
                </thead>
                <tbody>
                    <tr className="even-row">
                        <td>&lt; 11 personnes</td>
                        <td>Non</td>
                        <td>Oui (une seule étape de compétition, les préliminaires sont aussi la finale)</td>
                    </tr>
                    <tr className="odd-row">
                        <td>de 11 à 20 personnes</td>
                        <td>Non</td>
                        <td>Oui (5)</td>
                    </tr>
                    <tr className="even-row">
                        <td>de 21 à 30 personnes</td>
                        <td>Non</td>
                        <td>Oui (10)</td>
                    </tr>
                    <tr className="odd-row">
                        <td>de 31 à 45 personnes</td>
                        <td>Oui (16)</td>
                        <td>Oui (10)</td>
                    </tr>
                    <tr className="even-row">
                        <td>&gt; 45 personnes</td>
                        <td>Oui (24)</td>
                        <td>Oui (10)</td>
                    </tr>
                </tbody>
            </table>
            <p>
                Tout écart au tableau, par exemple ouvrir plus de places en finale qu'indiqué, doit être signalé au SCR4T avant la compétition, qui peut refuser l'altération. Si le tableau ci-dessus n'indique que 5 places en finale et qu'une sixième est ouverte le dernier couple classé n'aura pas de points SCR4T.
            </p>

            <h3 id="divisions">Système de divisions</h3>
            <p>Nous proposons à l'heure actuelle trois divisions : Initié, Intermédiaire, Avancé</p>
            <p>
                Passé l'événement de mise en place du système (Printemps 4 Temps 2022, voir <a href="/rules?ver=0#launch">les anciennes règles</a>), l'accès à une division donnée est déterminé par le nombre de points SCR4T accumulés dans une division, indiqués dans le tableau ci-dessous :
            </p>
            <table>
                <thead>
                    <tr>
                        <th className="th-division-width">Division</th>
                        <th>Points de cette division donnant le choix entre la division actuelle et la division suivante</th>
                        <th>Points de cette division obligeant à participer dans la division suivante</th>
                    </tr>
                </thead>
                <tbody>
                    <tr className="even-row">
                        <td>Initié</td>
                        <td>6</td>
                        <td>12</td>
                    </tr>
                    <tr className="odd-row">
                        <td>Intermédiaire</td>
                        <td>24</td>
                        <td>36</td>
                    </tr>
                    <tr className="even-row">
                        <td>Avancé</td>
                        <td>-</td>
                        <td>-</td>
                    </tr>
                </tbody>
            </table>
            <p>Dans tous les cas, si un•e compétiteur•ice marque 1 point dans une division, iel n'a plus accès aux divisions précédentes dans le rôle où le point a été obtenu.</p>
            <p>Des dérogations ponctuelles à ces règles sont possibles : voir <a href="#petition">"Demandes de dérogation"</a></p>
            <div className="nb">
                <b>NB : </b>des changements dans le nombre de divisions ou le nombre de points nécessaires pour passer d'une division à une autre seront possibles dans le futur, si le nombre de compétitions SCR4T et/ou de compétiteur-ices augmente. Aucun changement ne sera rétro-actif et tous seront annoncés préalablement. Une personne en division Intermédiaire (resp. Avancé), ne peut pas être privée de son droit de participer en division Intermédiaire (resp. Avancé). Une personne ayant gagné des points ne peut pas perdre ses points, sauf si la compétition à laquelle elle a participé n'a pas respecté les conditions pour rejoindre le SCR4T.
            </div>

            <h3 id="points">Système de points</h3>
            <p>Le nombre de points que peut gagner un•e compétiteur•ice est déterminé par le nombre de danseur•euse•s inscrit•e•s dans son rôle. Cela permet au point de représenter en partie la difficulté de la compétition : il est plus difficile d'arriver en finale quand il y a beaucoup de compétiteur•ice•s.</p>
            <p>Le tableau ci-dessous indique le nombre de points gagnés en fonction du rang obtenu lors de la finale et du nombre de danseur•euse•s inscrit•e•s dans leur rôle.</p>
            <table className="large-table">
                <thead>
                    <tr>
                        <th>Nb personnes dans le rôle</th>
                        <th>1ère place</th>
                        <th>2ème place</th>
                        <th>3ème place</th>
                        <th>4ème place</th>
                        <th>5ème place</th>
                        <th>6ème place</th>
                        <th>7ème place</th>
                        <th>8ème place</th>
                        <th>9ème place</th>
                        <th>10ème place</th>
                        <th>Demi-finaliste</th>
                    </tr>
                </thead>
                <tbody>
                    <tr className="even-row">
                        <td>&lt; 11 personnes</td>
                        <td>7</td>
                        <td>5</td>
                        <td>3</td>
                        <td>-</td>
                        <td>-</td>
                        <td>-</td>
                        <td>-</td>
                        <td>-</td>
                        <td>-</td>
                        <td>-</td>
                        <td>-</td>
                    </tr>
                    <tr className="odd-row">
                        <td>de 11 à 20 personnes</td>
                        <td>10</td>
                        <td>8</td>
                        <td>6</td>
                        <td>3</td>
                        <td>3</td>
                        <td>-</td>
                        <td>-</td>
                        <td>-</td>
                        <td>-</td>
                        <td>-</td>
                        <td>-</td>
                    </tr>
                    <tr className="even-row">
                        <td>de 21 à 30 personnes</td>
                        <td>12</td>
                        <td>10</td>
                        <td>8</td>
                        <td>6</td>
                        <td>6</td>
                        <td>3</td>
                        <td>3</td>
                        <td>3</td>
                        <td>3</td>
                        <td>3</td>
                        <td>-</td>
                    </tr>
                    <tr className="odd-row">
                        <td>de 31 à 45 personnes</td>
                        <td>14</td>
                        <td>12</td>
                        <td>10</td>
                        <td>8</td>
                        <td>8</td>
                        <td>6</td>
                        <td>6</td>
                        <td>3</td>
                        <td>3</td>
                        <td>3</td>
                        <td>1</td>
                    </tr>
                    <tr className="even-row">
                        <td>&gt; 45 personnes</td>
                        <td>16</td>
                        <td>14</td>
                        <td>12</td>
                        <td>10</td>
                        <td>10</td>
                        <td>8</td>
                        <td>8</td>
                        <td>6</td>
                        <td>6</td>
                        <td>6</td>
                        <td>2</td>
                    </tr>
                </tbody>
            </table>
            <p>L'ensemble des points obtenus dans des compétitions utilisant le SCR4T sera répertorié publiquement.</p>
            <p>Les points sont liés au rôle dansant de la personne. Une personne pratiquant les deux rôles en compétition a des points en leader et en follower. Elle ne concourra pas nécessairement dans la même division pour chacun de ses deux rôles.</p>
            <p>Les points sont liés à la division. Quand une personne passe en division intermédiaire, elle commence dans cette division avec zéro points intermédiaires.</p>

            <h3 id="petition">Demande de dérogation</h3>
            <h5>Cas nº1 : participer à une division suivante à la sienne</h5>
            <p>
                Une personne qui devrait s'inscrire en Initié (resp. Intermédiaire) d'après les règles ci-dessus peut faire une demande exceptionnelle pour participer en division Intermédiaire (resp. Avancé). 
                Cette demande doit être envoyée au SCR4T par e-mail et aux organisateurs de la compétition au moins une semaine avant la compétition en question, en justifiant la raison de la demande. 
                Celle-ci peut inclure (mais n'est pas exclue à) par exemple :
            </p>
            <ul>
                <li>Un•e professeur•e de cours réguliers de Rock 4 Temps qui ne souhaite pas être en compétition avec ses élèves ;</li>
                <li>Une personne ayant très souvent été juge ou scoreur•euse lors de compétitions SCR4T, l'empêchant de participer dans une division et donc d'y marquer des points.</li>
            </ul>
            <p>La demande est soumise au SCR4T et à la président•e du jury de la compétition en question, qui l'acceptent ou non. Si la demande est acceptée, la dérogation vaut uniquement pour la compétition en question. La personne pourra continuer à participer en division Intermédiaire (resp. Avancé) si et seulement si elle marque 1 point lors de la compétition.</p>
            <p>Une dérogation pour participer dans une division ne peut être acceptée que s'il y a assez de personnes inscrites “de droit” à la division en question, permettant ainsi l'ouverture de la division lors de la compétition.</p>
            <h5>Cas n°2 : participer à une division précédente à la sienne</h5>
            <p>
                Une personne qui devrait s'inscrire en division Intermédiaire (resp. Avancé) d'après les règles ci-dessus peut faire une demande pour participer en division Initié (resp. Intermédiaire) si elle n'a pas participé à une compétition depuis au moins 3 ans (à la date de la compétition pour laquelle la dérogation est demandée). 
                <br/>Cette demande doit être envoyée au SCR4T et aux organisateurs de la compétition par e-mail au moins une semaine avant la compétition en question. 
                La demande est soumise au SCR4T et à la président•e du jury de la compétition en question, qui l'accepte ou non. 
                Si la demande est acceptée, la personne pourra continuer à participer dans la nouvelle division jusqu'à marquer 1 point.
            </p>

        </>
    );
}

export default RulesV1;