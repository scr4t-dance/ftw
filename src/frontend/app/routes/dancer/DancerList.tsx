import type { Route } from './+types/DancerList';
import React from 'react';
import { Link } from "react-router";
import { BareDancerListComponent, DancerListComponent } from '@routes/dancer/DancerComponents';
import { getApiDancerId, getApiDancers } from '~/hookgen/dancer/dancer';



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

function DancerList({ loaderData }: Route.ComponentProps) {

    const {dancer_list, dancer_data} = loaderData;
    return (
        <>
            <Link to={`new`}>
                Créer un-e nouvel-le compétiteur-euse
            </Link>
            <BareDancerListComponent dancer_list={dancer_list} dancer_data={dancer_data} />
        </>
    );
}

export default DancerList;