import type { Route } from "./+types/CompetitionPromotionsRoute"

import { Link } from "react-router";

import type { BibList, Competition, CompetitionId, Event, EventId, PhaseId } from "@hookgen/model";

import { getGetApiCompIdPromotionsQueryOptions, getGetApiCompIdResultsQueryOptions, useGetApiCompIdPromotions, useGetApiCompIdResults } from "~/hookgen/results/results";
import { CompetitionNavigation, CompetitionResults } from "./CompetitionComponents";

import { dehydrate, QueryClient } from '@tanstack/react-query';
import { getGetApiEventIdQueryOptions } from '@hookgen/event/event';
import { getGetApiCompIdQueryOptions, useGetApiCompId } from '@hookgen/competition/competition';

export async function loader({ params }: Route.LoaderArgs) {

    const queryClient = new QueryClient();
    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;
    await queryClient.prefetchQuery(getGetApiEventIdQueryOptions(id_event));
    await queryClient.prefetchQuery(getGetApiCompIdQueryOptions(id_competition));
    await queryClient.prefetchQuery(getGetApiCompIdResultsQueryOptions(id_competition));
    await queryClient.prefetchQuery(getGetApiCompIdPromotionsQueryOptions(id_competition));

    return { dehydratedState: dehydrate(queryClient) };
}


export default function CompetitionPromotions({
    params,
}: Route.ComponentProps) {

    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;

    //const url = `/events/${loaderData.id_event}/competitions/${loaderData.id_competition}`;
    const url = "../";

    const { data: competition, isSuccess: isSuccessComp } = useGetApiCompId(id_competition)
    if (!isSuccessComp) return <div>Chargement Competition</div>;
    const { data: results_data, isSuccess: isSuccessResults } = useGetApiCompIdResults(id_competition)
    if (!isSuccessResults) return <div>Chargement Competition</div>;
    const { data: promotions_data, isSuccess: isSuccessPromotion } = useGetApiCompIdPromotions(id_competition)
    if (!isSuccessPromotion) return <div>Chargement Competition</div>;


    return (
        <>
            <h1>Compétition {competition?.name}</h1>
            <CompetitionNavigation url={url} />
            <p>Type : {competition?.kind}</p>
            <p>Catégorie : {competition?.category}</p>
            <CompetitionResults id_competition={id_competition} results_data={results_data} promotions_data={promotions_data} />
        </>
    );
}
