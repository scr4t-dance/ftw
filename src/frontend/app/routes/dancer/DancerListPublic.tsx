import type { Route } from './+types/DancerListPublic';

import { Link } from "react-router";
import { DancerListComponent } from '@routes/dancer/DancerComponents';
import { getGetApiDancerIdQueryOptions, getGetApiDancersQueryOptions } from '~/hookgen/dancer/dancer';
import { dehydrate, QueryClient } from '@tanstack/react-query';



export async function loader({ }: Route.LoaderArgs) {

    const queryClient = new QueryClient();

    const dancer_list = await queryClient.fetchQuery(getGetApiDancersQueryOptions());
    await Promise.all(
        dancer_list.dancers.map((id_dancer) => queryClient.prefetchQuery(getGetApiDancerIdQueryOptions(id_dancer)))
    );


    return { dehydratedState: dehydrate(queryClient) };
}

function DancerList({ }: Route.ComponentProps) {

    return (
        <>
            <DancerListComponent />
        </>
    );
}

export default DancerList;
