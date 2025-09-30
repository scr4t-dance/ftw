
import React from 'react';
import { Link, useLocation } from "react-router";


import { type Event, type EventId, type EventIdList, type Date } from "@hookgen/model";
import PageTitle from '@routes/index/PageTitle';
import { CompetitionListComponent } from '@routes/competition/CompetitionComponents';

export type loaderProps = Promise<{
    event_list: EventIdList;
}>


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

function capitalizeFirstLetter(str: string): string {
    return str.charAt(0).toUpperCase() + str.slice(1);
}

function EventDetails({ id, data, index }: { id: EventId, data: Event, index: number }) {

    if (!data) return null;

    const event = data;
    const date = new Date(event.start_date?.year, event.start_date?.month, event.start_date?.day);

    // https://stackoverflow.com/questions/1643320/get-month-name-from-date
    // can be slow, may need to be optimized, probably not needed for our volume of data
    const month = date.toLocaleString('fr-FR', { month: 'long' });
    const year = event.start_date?.year;

    return (
        <tr key={id}
            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
            <td>
                <Link to={`${id}`}>
                    {event.name}
                </Link>
            </td>
            <td>{capitalizeFirstLetter(month)}</td>
            <td>{year}</td>
        </tr>
    );
}

export function EventListComponent({ event_list, event_data }: { event_list: EventIdList, event_data: Event[] }) {

    const location = useLocation();
    const url = location.pathname.includes("event") ? "" : "events/";

    return (
        <>
            <PageTitle title="Événements" />
            <h1>Événements partenaires</h1>
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
                                <Link to={`${url}${id}`}>
                                    {name}
                                </Link>
                            </td>
                            <td>{month}</td>
                            <td>{year}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
            <h1>Liste chronologique</h1>
            <table>
                <tbody>
                    <tr>
                        <th>Nom de l'événement</th>
                        <th>Mois</th>
                        <th>Année</th>
                    </tr>

                    {event_list.events && event_list.events.map((eventId: EventId, index: number) => (
                        <EventDetails key={eventId} data={event_data[index]} id={eventId} index={index} />
                    ))}
                </tbody>
            </table>
        </>
    );
}

export function EventDetailsComponent({ event, id_event }: { event: Event, id_event: EventId }) {

    if (!event) return <p>Pas de données sur l’événement {id_event}.</p>;

    const formatDate = (date: Date | undefined): string => {
        if (date?.year && date?.month && date?.day) {
            return `${date.year}-${String(date.month).padStart(2, '0')}-${String(date.day).padStart(2, '0')}`;
        }
        return '';
    };

    return (
        <>
            <h1>{event?.name}</h1>
            <p>Date de début : {formatDate(event?.start_date)}</p>
            <p>Date de fin : {formatDate(event?.end_date)}</p>
            <Link to={`competitions`}>Liste des competitions</Link>
            <CompetitionListComponent id_event={id_event} />
        </>
    );

}

export function EventDetailsAdminComponent({ event, id_event }: { event: Event, id_event: EventId }) {

    if (!event) return <p>Pas de données sur l’événement {id_event}.</p>;

    const formatDate = (date: Date | undefined): string => {
        if (date?.year && date?.month && date?.day) {
            return `${date.year}-${String(date.month).padStart(2, '0')}-${String(date.day).padStart(2, '0')}`;
        }
        return '';
    };

    return (
        <>
            <h1>{event?.name}</h1>
            <p>Date de début : {formatDate(event?.start_date)}</p>
            <p>Date de fin : {formatDate(event?.end_date)}</p>
            <Link to="competitions/new">Créer une competition</Link>
            <Link to="competitions">Liste des competitions</Link>
            <Link to="bibs">Liste des dossards</Link>
            <CompetitionListComponent id_event={id_event} />
        </>
    );

}
