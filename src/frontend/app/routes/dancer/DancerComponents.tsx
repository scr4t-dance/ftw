import React from 'react';
import { useGetApiDancers, useGetApiDancerId, getGetApiDancerIdQueryOptions } from '@hookgen/dancer/dancer';

import { DivisionItem, DivisionsItem, type Dancer, type DancerId, type DancerIdList, type Divisions } from "@hookgen/model";
import { Link, useLocation } from "react-router";
import DancerCompetitionHistory from '@routes/dancer/DancerCompetitionHistory';
import { SaveDancerFormComponent } from '@routes/dancer/NewDancerForm';
import { useQueries } from '@tanstack/react-query';


const divisionColors: Record<DivisionsItem, string> = {
    [DivisionsItem.None]: '#9ca3af',
    [DivisionsItem.Novice]: '#3C1',
    [DivisionsItem.Novice_Intermediate]: '#1BC',
    [DivisionsItem.Intermediate]: '#08C',
    [DivisionsItem.Intermediate_Advanced]: '#94E',
    [DivisionsItem.Advanced]: '#E43',
};

export function Badge({ role, divisions }: { role: string, divisions: Divisions }) {

    // exclude the croisillon # for shields.io service
    const badge_color = divisionColors[divisions[0]].slice(1);

    return (
        <img className="role_badge" alt={`${role}-${divisions}`} src={`https://img.shields.io/badge/${role}-${divisions}-${badge_color}`} />
    );
}

function DancerDetails({ id_dancer, dancer, index }: { id_dancer: DancerId, dancer: Dancer, index: number }) {

    const location = useLocation();
    const url = location.pathname.includes("admin") ? "/admin/dancers/" : "/dancers/";


    return (
        <tr key={id_dancer}
            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
            <td>
                <Link to={`${url}${id_dancer}`}>
                    {dancer.last_name}
                </Link>
            </td>
            <td>
                <Link to={`${url}${id_dancer}`}>
                    {dancer.first_name}
                </Link>
            </td>
            <td>
                {dancer.as_follower[0] !== DivisionsItem.None &&
                    <Badge role='F' divisions={dancer.as_follower} />
                }
            </td>
            <td>
                {dancer.as_leader[0] !== DivisionsItem.None &&
                    <Badge role='L' divisions={dancer.as_leader} />
                }
            </td>
        </tr>

    );
}

export function BareDancerListComponent({ dancer_list, dancer_data }: { dancer_list: DancerIdList, dancer_data: Dancer[] }) {

    if (dancer_list.dancers.length != dancer_data.length) return <p>Invalid data for BareDancerListComponent</p>

    return (
        <>
            <h1>Liste Compétiteur-ices</h1>
            <table>
                <tbody>
                    <tr>
                        <th>Nom</th>
                        <th>Prénom</th>
                        <th>Division follower</th>
                        <th>Division leader</th>
                    </tr>

                    {dancer_list?.dancers?.map((dancerId, index) => (
                        <DancerDetails key={dancerId} id_dancer={dancerId} dancer={dancer_data[index]} index={index} />
                    ))}
                </tbody>
            </table>
        </>
    );
}

export function InnerDancerListComponent({ dancer_list }: { dancer_list: DancerIdList }) {

    const dancerDataQueries = useQueries({
        queries: dancer_list.dancers.map((dancerId) => ({
            ...getGetApiDancerIdQueryOptions(dancerId),
            enabled: true,
        })),
    });

    const isLoading = dancerDataQueries.some((query) => query.isLoading);
    const isError = dancerDataQueries.some((query) => query.isError);


    if (isLoading) return <div>Chargement des compétiteur-euses...</div>;
    if (isError) return (
        <div>
            Error loading judges data
            {
                dancerDataQueries.map((query) => {
                    return (<p>{query.error?.message}</p>);
                })
            }
        </div>);

    const dancer_data = dancerDataQueries.map((query) => query.data as Dancer);

    return (
        <>
            <BareDancerListComponent dancer_list={dancer_list as DancerIdList} dancer_data={dancer_data} />
        </>
    );
}


export function DancerListComponent() {

    const { data: dancer_list, isLoading, isError, error } = useGetApiDancers();

    if (isLoading) return <div>Chargement des compétiteur-euses...</div>;
    if (isError) return <div>Erreur: {(error as any).message}</div>;

    return (
        <>
            <InnerDancerListComponent dancer_list={dancer_list as DancerIdList} />
        </>
    );
}


export function DancerPageComponent({ dancer, id_dancer }: { dancer: Dancer, id_dancer: DancerId }) {

    return (
        <>
            <DancerPagePublicComponent dancer={dancer} id_dancer={id_dancer} />
            <p>Birthday: "Hidden"</p>
            <p>Email : "Hidden"</p>
            <h1>Mise à jour données</h1>
            <SaveDancerFormComponent id_dancer={id_dancer} dancer={dancer} />

        </>
    );
}

export function DancerPagePublicComponent({ dancer, id_dancer }: { dancer: Dancer, id_dancer: DancerId }) {

    return (
        <>
            <h1 className="dancer_name">{dancer.first_name}, {dancer.last_name}</h1>
            <DancerCompetitionHistory />

        </>
    );
}
