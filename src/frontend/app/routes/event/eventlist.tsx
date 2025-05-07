import "~/styles/ContentStyle.css";

import React from 'react';
import { Link } from "react-router";


import {useGetApiEvents, useGetApiEventId} from '@hookgen/event/event';
import { type EventId, type EventIdList } from "@hookgen/model";

import PageTitle from "@routes/index/PageTitle";
import Header from "@routes/header/header";
import Footer from "@routes/footer/footer";


const eventListlink = "/event"
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

    const { data, isLoading, error } = useGetApiEvents();

    const event_array = data?.data as EventIdList;

    if (isLoading) return <div>Chargement des événements...</div>;
    if (error) return <div>Erreur: {(error as any).message}</div>;

    return (
        <>
            <PageTitle title="Événements" />
            <Header />
            <div className="content-container">

                <Link to={`/events/new`}>
                    Créer un nouvel événement
                </Link>
                <h1>Événements partenaires</h1>
                <ul>
                    {eventsPartners.map(({name, link}, index) => (
                        <li key={index}><a target="_blank" rel="noreferrer" href={link}>{name}</a></li>
                    ))}
                </ul>

                <h1>Liste Hardcodée</h1>
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
                                    <a href={`${eventListlink}${id}`}>
                                        {name}
                                    </a>
                                </td>
                                <td>{month}</td>
                                <td>{year}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
                <h1>Liste API</h1>
                <table>
                    <tbody>
                        <tr>
                            <th>Nom de l'événement</th>
                            <th>Mois</th>
                            <th>Année</th>
                        </tr>

                        {event_array.events.map((eventId, index) => (
                            <EventDetails key={eventId} id={eventId} index={index}/>
                        ))}
                    </tbody>
                </table>
            </div>
            <Footer />
        </>
    );
}


function EventDetails({ id, index }: { id: EventId, index: number }) {
  const { data, isLoading } = useGetApiEventId(id);

  if (isLoading) return <tr><td>Chargement...</td></tr>;
  if (!data) return null;

  const event = data.data;
  const month = event.start_date?.month;
  const year = event.start_date?.year;

  return (
    <tr key={id}
        className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
        <td>
        <Link to={`${eventListlink}/${id}`}>
            {event.name}
        </Link>
        </td>
        <td>{month}</td>
        <td>{year}</td>
    </tr>
  );
}

export default EventList;