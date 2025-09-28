import type { Route } from './+types/DancerListPublic';

import React from 'react';
import { BareDancerListComponent } from '@routes/dancer/DancerComponents';
import { Link } from 'react-router';
import { getApiDancerId, getApiDancers } from '@hookgen/dancer/dancer';


export async function loader({ }: Route.LoaderArgs) {

    const dancer_list = await getApiDancers();
    const dancer_data = await Promise.all(
        dancer_list.dancers.map((id_dancer) => getApiDancerId(id_dancer))
    );
    return {
        dancer_list,
        dancer_data,
    };
}

function DancerListPublic({ loaderData }: Route.ComponentProps) {

    const {dancer_list, dancer_data} = loaderData;
    return (
        <>
            <Link to={`/dancers/new`}>
                Créer un-e nouvel-le compétiteur-euse
            </Link>
            <BareDancerListComponent dancer_list={dancer_list} dancer_data={dancer_data} />
        </>
    );
}
export default DancerListPublic;