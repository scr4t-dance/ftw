import "~/styles/ContentStyle.css";

import { useGetApiCompId } from '@hookgen/competition/competition';
import { useGetApiCompIdBibs } from '@hookgen/bib/bib';

import { type Competition, type CompetitionId } from "@hookgen/model";
import { Link, useParams } from "react-router";
import { useGetApiEventId } from "@hookgen/event/event";
import NewBibForm from "./NewBibForm";
import { BareBibListComponent } from "./BibList";

function CompetitionDetails() {

    let { id_competition } = useParams();
    let id_competition_number = Number(id_competition) as CompetitionId;
    const { data, isLoading } = useGetApiCompId(id_competition_number);


    const competition = data as Competition;

    const { data: dataEvent } = useGetApiEventId(Number(competition?.event));
    const event = dataEvent;

    const {
        data: dataBib,
        isLoading: isLoadingBib,
        error: errorBib
    } = useGetApiCompIdBibs(id_competition_number);
    const bib_list = dataBib?.bibs ?? [];

    console.log("bib_list", bib_list, isLoadingBib, errorBib);

    if (isLoading) return <div>Chargement...</div>;
    if (!data) return null;

    return (
        <>

            <h1>Compétition {competition?.name}</h1>


            <p><Link to={`/events/${competition?.event}`}>
                Evénement {event?.name}
            </Link></p>
            <p>Type : {competition?.kind}</p>
            <p>Catégorie : {competition?.category}</p>

            {isLoadingBib &&
                <p>Chargement de la liste des dossards</p>}
            {!isLoadingBib && bib_list &&
                <>
                    <BareBibListComponent bib_list={bib_list} />
                </>
            }

            <NewBibForm default_competition={id_competition_number} />
        </>
    );
}

export default CompetitionDetails;