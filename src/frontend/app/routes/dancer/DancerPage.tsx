import type { Route } from './+types/DancerPage';
import React from 'react';

import { type DancerId } from "@hookgen/model";
import { getApiDancerId } from '@hookgen/dancer/dancer';
import { DancerPageComponent } from './DancerComponents';

export async function loader({ params }: Route.LoaderArgs) {

    const { id_dancer: id_dancer_string } = params;
    const id_dancer = Number(id_dancer_string) as DancerId;

    const dancer = await getApiDancerId(id_dancer);
    return {
        id_dancer,
        dancer,
    };
}

function DancerPage({loaderData}: Route.ComponentProps) {

    const {id_dancer, dancer} = loaderData;
    return (
        <DancerPageComponent dancer={dancer} id_dancer={id_dancer} />
    );
}

export default DancerPage;

export const handle = {
  breadcrumb: () => "Dancer"
};
