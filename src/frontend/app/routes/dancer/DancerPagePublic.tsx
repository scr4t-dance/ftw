import type { Route } from './+types/DancerPagePublic';
import React from 'react';

import { type DancerId } from "@hookgen/model";
import { getApiDancerId } from '@hookgen/dancer/dancer';
import { DancerPagePublicComponent } from '@routes/dancer/DancerComponents';


export async function loader({ params }: Route.LoaderArgs) {

    const { id_dancer: id_dancer_string } = params;
    const id_dancer = Number(id_dancer_string) as DancerId;

    const dancer = await getApiDancerId(id_dancer);
    return {
        id_dancer,
        dancer,
    };
}

function DancerPagePublic({loaderData}:Route.ComponentProps) {


    const {id_dancer, dancer} = loaderData;

    return (
        <DancerPagePublicComponent dancer={dancer} id_dancer={id_dancer} />
    );
}

export default DancerPagePublic;

export const handle = {
  breadcrumb: () => "Competition"
};
