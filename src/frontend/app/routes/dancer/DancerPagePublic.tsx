import type { Route } from './+types/DancerPagePublic';
import React from 'react';

import { type DancerId } from "@hookgen/model";
import { getGetApiDancerIdQueryOptions } from '@hookgen/dancer/dancer';
import { DancerPagePublicComponent } from '@routes/dancer/DancerComponents';
import { dehydrate, QueryClient } from '@tanstack/react-query';

export async function loader({ params }: Route.LoaderArgs) {

    const id_dancer = Number(params.id_dancer) as DancerId;

    const queryClient = new QueryClient();

    queryClient.prefetchQuery(getGetApiDancerIdQueryOptions(id_dancer));

    return { dehydratedState: dehydrate(queryClient) };
}

function DancerPagePublic({params}:Route.ComponentProps) {

    const id_dancer = Number(params.id_dancer) as DancerId;
    return (
        <DancerPagePublicComponent id_dancer={id_dancer} />
    );
}

export default DancerPagePublic;

export const handle = {
  breadcrumb: () => "Competition"
};
