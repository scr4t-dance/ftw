import "../styles/ContentStyle.css";

import { useGetApiCompId, useGetApiCompIdDancers } from '../hookgen/competition/competition';

import PageTitle from "./PageTitle";
import Header from "./Header";
import Footer from "./Footer";
import { CompetitionId } from "hookgen/model";
import { Link, useParams } from "react-router";
import { useGetApiEventId } from "hookgen/event/event";
import NewBibForm from "./NewBibForm";
import { BareBibListComponent } from "./BibList";

function CompetitionPage() {

    let { id_competition } = useParams();
    let id_competition_number = Number(id_competition) as CompetitionId;
    const { data, isLoading } = useGetApiCompId(id_competition_number);


    const competition = data?.data;

    const { data: dataEvent } = useGetApiEventId(Number(competition?.event));
    const event = dataEvent?.data;

    const {
        data: dataBib,
        isLoading: isLoadingBib,
        error: errorBib
    } = useGetApiCompIdDancers(id_competition_number);
    const bib_list = dataBib?.data?.bibs ?? [];

    console.log("bib_list", bib_list, isLoadingBib, errorBib);

    if (isLoading) return <div>Chargement...</div>;
    if (!data) return null;

    return (
        <>
            <PageTitle title={"Compétition " + competition?.name} />
            <Header />
            <div className="content-container">

                <h1>Compétition {competition?.name}</h1>


                <p><Link to={`/events/${competition?.event}`}>
                    Evénement {event?.name}
                </Link></p>
                <p>Type : {competition?.kind}</p>
                <p>Catégorie : {competition?.category}</p>

                <NewBibForm default_competition={id_competition_number} />

                {isLoadingBib &&
                    <p>Chargement de la liste des dossards</p>}
                {!isLoadingBib && bib_list &&
                    <>
                        <BareBibListComponent bib_list={bib_list} />
                    </>
                }
            </div>
            <Footer />
        </>
    );
}

export default CompetitionPage;