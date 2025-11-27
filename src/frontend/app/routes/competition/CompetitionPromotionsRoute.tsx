import type { Route } from "./+types/CompetitionPromotionsRoute"

import { Link } from "react-router";

import type { CompetitionId, DancerCompetitionResultsList, PromotionList } from "@hookgen/model";
import { CompetitionNavigation, CompetitionResults } from "@routes/competition/CompetitionComponents";
import { useGetApiCompId } from "@hookgen/competition/competition";
import { useGetApiCompIdPromotions, useGetApiCompIdResults } from "~/hookgen/results/results";


export async function loader({ params }: Route.LoaderArgs) {


}

export default function CompetitionPromotions({
    params,
}: Route.ComponentProps) {

    const id_competition = Number(params.id_competition) as CompetitionId;

    const { data: competition, isLoading: isLoadingCompetition, isError: isErrorCompetition } = useGetApiCompId(id_competition)
    const { data: results_data, isLoading: isLoadingResults, isError: isErrorResults } = useGetApiCompIdResults(id_competition)
    const { data: promotions_data, isLoading: isLoadingPromotion, isError: isErrorPromotions } = useGetApiCompIdPromotions(id_competition)

    if (isLoadingCompetition) return (<div>Chargement de la competition</div>);
    if (isErrorCompetition) return (<div>Erreur chargement de la competition</div>);
    if (isLoadingResults) return (<div>Chargement de la competition</div>);
    if (isErrorResults) return (<div>Erreur chargement de la competition</div>);
    if (isLoadingPromotion) return (<div>Chargement de la competition</div>);
    if (isErrorPromotions) return (<div>Erreur chargement de la competition</div>);


    //const url = `/events/${loaderData.id_event}/competitions/${loaderData.id_competition}`;
    const url = "../";

    return (
        <>
            <h1>Compétition {competition?.name}</h1>
            <CompetitionNavigation url={url} />
            <p>Type : {competition?.kind}</p>
            <p>Catégorie : {competition?.category}</p>
            <CompetitionResults id_competition={id_competition}
                results_data={results_data as DancerCompetitionResultsList}
                promotions_data={promotions_data as PromotionList} />
        </>
    );
}
