import type { Route } from "./+types/EventList";

import React from 'react';
import { Link } from "react-router";


import { getApiEvents, getApiEventId } from '@hookgen/event/event';
import { type EventId, type EventIdList, type Event } from "@hookgen/model";

import PageTitle from "@routes/index/PageTitle";


const eventListlink = "/events"
// TEMPORAIRE
const eventsPartners = [
    {
        name: "4 Temps Winter Cup",
        link: "https://fusion4temps.wordpress.com/4-temps-winter-cup-2024/"
    },
    {
        name: "4 Temptastiques",
        link: "https://www.facebook.com/4temptastiques"
    },
    {
        name: "Printemps 4 Temps",
        link: "https://www.printemps4temps.com/"
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

export async function loader({ }: Route.LoaderArgs) {
    const event_list = await getApiEvents();
    const event_data = await Promise.all(
        event_list.events.map((id_event) => getApiEventId(id_event))
    );

    return {
        event_list,
        event_data,
    };
}


function EventDetails({ id, data, index }: { id: EventId, data: Event, index: number }) {

    if (!data) return null;

    const event = data;
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

export default function EventList({
    loaderData,
}: Route.ComponentProps) {

    const event_list: EventIdList = loaderData.event_list;

    return (
        <>
            <PageTitle title="Événements" />
            <Link to={`/events/new`}>
                Créer un nouvel événement
            </Link>
            <h1>Événements partenaires</h1>
            <ul>
                {eventsPartners.map(({ name, link }, index) => (
                    <li key={index}><a target="_blank" rel="noreferrer" href={link}>{name}</a></li>
                ))}
            </ul>

            <h1>Liste officielle</h1>
            <table>
                <tbody>
                    <tr>
                        <th>Nom de l'événement</th>
                        <th>Mois</th>
                        <th>Année</th>
                    </tr>
                    {events.map(({ id, name, month, year }, index) => (
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

                    {event_list.events && event_list.events.map((eventId: EventId, index: number) => (
                        <EventDetails key={eventId} data={loaderData.event_data[index]} id={eventId} index={index} />
                    ))}
                </tbody>
            </table>
        </>
    );
}
