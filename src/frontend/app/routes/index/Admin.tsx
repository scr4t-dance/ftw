import { Link } from "react-router";
import type { Route } from "./+types/Admin";

export default function EventsHomeAdmin({ }: Route.ComponentProps) {

  return (
    <>
      <p>
        <Link to="events">Events</Link>
      </p>
      <p>
        <Link to="dancers">Dancers</Link>
      </p>
      <p>
        <Link to="events/1">Evénement en cours</Link>
      </p>
      <p>
        TODO : Page d'accueil de l'événement principal / en cours.
      </p>
    </>
  );
}
