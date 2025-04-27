import "../styles/ContentStyle.css";

import React from 'react';
import { useGetApiEventId } from '../hookgen/event/event';

import PageTitle from "./PageTitle";
import Header from "./Header";
import Footer from "./Footer";
import { EventId, Date } from "hookgen/model";
import { useParams } from "react-router";

function EventPage() {

    let { id_event } = useParams();
    let id_event_number = Number(id_event) as EventId;
    const { data, isLoading, isError, error } = useGetApiEventId(id_event_number);

    if (isLoading) return <div>Chargement...</div>;
    if (!data) return null;

    const event = data.data;

    if (isLoading) return <div>Chargement des événements...</div>;
    if (isError) return <div>Erreur: {(error as any).message}</div>;

    const formatDate = (date: Date | undefined): string => {
        if (date?.year && date?.month && date?.day) {
            return `${date.year}-${String(date.month).padStart(2, '0')}-${String(date.day).padStart(2, '0')}`;
        }
        return '';
    };

    return (
        <>
            <PageTitle title={"Événement " + event?.name} />
            <Header />
            <div className="content-container">
                <h1>{event?.name}</h1>
                <p>Date de début : {formatDate(event?.start_date)}</p>
                <p>Date de fin : {formatDate(event?.end_date)}</p>
            </div>
            <Footer />
        </>
    );
}

export default EventPage;