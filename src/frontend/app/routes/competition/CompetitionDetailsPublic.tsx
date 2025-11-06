import type { Route } from "./+types/CompetitionDetailsPublic"

import type { CompetitionId, EventId, } from "@hookgen/model";
import { dehydrate, QueryClient } from "@tanstack/react-query";
import { getGetApiCompIdBibsQueryOptions } from "~/hookgen/bib/bib";
import { getGetApiCompIdQueryOptions } from "~/hookgen/competition/competition";
import { getGetApiEventIdQueryOptions } from "~/hookgen/event/event";
import { CompetitionDetailsComponent } from "@routes/competition/CompetitionComponents";


export async function loader({ params }: Route.LoaderArgs) {

    const queryClient = new QueryClient();
    const id_event = Number(params.id_event) as EventId;
    await queryClient.prefetchQuery(getGetApiEventIdQueryOptions(id_event));
    const id_competition = Number(params.id_competition) as CompetitionId;
    await queryClient.prefetchQuery(getGetApiCompIdQueryOptions(id_competition));
    await queryClient.prefetchQuery(getGetApiCompIdBibsQueryOptions(id_competition));

    return { dehydratedState: dehydrate(queryClient) };
}


export default function CompetitionDetailsRoute({
    params,
}: Route.ComponentProps) {

    const id_event = Number(params.id_event) as EventId;
    const id_competition = Number(params.id_competition) as CompetitionId;

    return (<CompetitionDetailsComponent id_competition={id_competition} isAdmin={false} />);
}
