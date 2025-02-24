import "../styles/ContentStyle.css"

import Header from "./Header"

const eventListlink = "events/"
// TEMPORAIRE
const eventsPartners = [
    {
        name:"4 Temps Winter Cup",
        link:"https://fusion4temps.wordpress.com/4-temps-winter-cup-2024/"
    },
    {
        name:"4 Temptastiques",
        link:"https://www.facebook.com/4temptastiques"
    },
    {
        name:"Printemps 4 Temps",
        link:"https://www.printemps4temps.com/"
    },
]
// TEMPORAIRE
const events = [
    {
        id: 19,
        name: "4 Temps Winter Cup",
        month: "Janvier",
        year: "2024"
    },
    {
        id: 20,
        name: "Printemps 4 Temps",
        month: "Mai",
        year: "2024"
    },
    {
        id: 23,
        name: "Concours Chorégraphie ENS Uml",
        month: "Avril",
        year: "2024"
    },
    {
        id: 21,
        name: "4 Temps Winter Cup",
        month: "Janvier",
        year: "2025"
    },
    {
        id: 22,
        name: "4 Temptastiques",
        month: "Mars",
        year: "2025"
    }
]

function EventList() {
    return (
        <div>
            <Header />
            <div className="content-container">
                <h1>Événements partenaires</h1>
                <ul>
                    {eventsPartners.map(({name, link}, index) => (
                        <li key={index}><a className="link" target="_blank" href={link}>{name}</a></li>
                    ))}
                </ul>

                <h1>Liste chronologique</h1>
                <table>
                    <tbody>
                        <tr>
                            <th>Nom de l'événement</th>
                            <th>Mois</th>
                            <th>Année</th>
                        </tr>
                        {events.map(({id, name, month, year}, index) => (
                            <tr key={id} 
                                className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
                                <td>
                                    <a href={`${eventListlink}${id}`} className="link">
                                        {name}
                                    </a>
                                </td>
                                <td>{month}</td>
                                <td>{year}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
}

export default EventList;