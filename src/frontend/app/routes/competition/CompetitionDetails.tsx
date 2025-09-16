import "~/styles/ContentStyle.css";

import { getApiCompId } from '@hookgen/competition/competition';
import { useGetApiCompIdBibs } from '@hookgen/bib/bib';

import type { Competition, CompetitionId } from "@hookgen/model";
import { Link } from "react-router";
import { NewPhaseForm } from "../phase/NewPhaseForm";
import { PhaseList } from "../phase/PhaseList";
import { NewBibForm } from "../bib/NewBibForm";
import { BareBibListComponent } from "../bib/BibList";
import type { Route } from "./+types/CompetitionDetails";
import { useGetApiEventId } from "~/hookgen/event/event";

export async function loader({ params }: Route.LoaderArgs) {

    const id_competition = parseInt(params.id_competition as string) as CompetitionId;
    const compQuery = await getApiCompId(id_competition);
    return compQuery;
}


export async function clientLoader({
    serverLoader,
    params,
}: Route.ClientLoaderArgs) {

    const id_competition = parseInt(params.id_competition as string) as CompetitionId;
    const compQuery = await getApiCompId(id_competition);
    const serverData = await serverLoader();
    return { ...serverData, ...compQuery };
}

// HydrateFallback is rendered while the client loader is running
export function HydrateFallback({ params }: Route.LoaderArgs) {
    return <div>Chargement de la compétition {params.id_competition}...</div>;
}

function CompetitionDetails({
    params,
    loaderData,
}: Route.ComponentProps) {

    const id_competition = parseInt(params.id_competition) as CompetitionId;
    const data = loaderData;

    const competition = data as Competition;

    const { data: dataEvent } = useGetApiEventId(Number(competition?.event));
    const event = dataEvent;

    const {
        data: dataBib,
        isLoading: isLoadingBib,
        error: errorBib
    } = useGetApiCompIdBibs(id_competition);
    const bib_list = dataBib?.bibs ?? [];

    console.log("CompetitionDetails", id_competition);

    return (
        <>

            <h1>Compétition {competition?.name}</h1>


            <p><Link to={`/events/${competition?.event}`}>
                Evénement {event?.name}
            </Link></p>
            <p>Type : {competition?.kind}</p>
            <p>Catégorie : {competition?.category}</p>
            <PhaseList id_competition={parseInt(params.id_competition)} />
            <NewPhaseForm default_competition={id_competition} />

            {isLoadingBib &&
                <p>Chargement de la liste des dossards</p>}
            {!isLoadingBib && bib_list &&
                <>
                    <BareBibListComponent bib_list={bib_list} />
                </>
            }

            <NewBibForm default_competition={id_competition} />
        </>
    );
}

export default CompetitionDetails;
