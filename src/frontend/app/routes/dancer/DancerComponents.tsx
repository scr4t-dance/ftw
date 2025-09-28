import React from 'react';
import { useGetApiDancers, useGetApiDancerId, getGetApiDancerIdQueryOptions } from '@hookgen/dancer/dancer';

import { type Dancer, type DancerId, type DancerIdList } from "@hookgen/model";
import { Link } from "react-router";
import DancerCompetitionHistory from './DancerCompetitionHistory';
import { SaveDancerFormComponent } from './NewDancerForm';
import { useQueries } from '@tanstack/react-query';

const dancerLink = "dancers/"

function DancerDetails({ id_dancer, dancer, index }: { id_dancer: DancerId, dancer: Dancer, index: number }) {

    return (
        <tr key={id_dancer}
            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
            <td>
                <Link to={`/${dancerLink}${id_dancer}`}>
                    {id_dancer}
                </Link>
            </td>
            <td>
                <Link to={`/${dancerLink}${id_dancer}`}>
                    {dancer.last_name}
                </Link>
            </td>
            <td>
                <Link to={`/${dancerLink}${id_dancer}`}>
                    {dancer.first_name}
                </Link>
            </td>
            <td>{dancer.as_follower}</td>
            <td>{dancer.as_leader}</td>
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
                        <th>ID</th>
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

export function InnerDancerListComponent({dancer_list} : {dancer_list: DancerIdList}) {

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
            <h1>{dancer?.last_name + " " + dancer.first_name}</h1>
            <p>Division follower : {dancer?.as_follower}</p>
            <p>Division leader : {dancer?.as_leader}</p>
            <p>Birthday: "Hidden"</p>
            <p>Email : "Hidden"</p>
            <h1>List de compétitions: </h1>
            <DancerCompetitionHistory />
            <h1>Mise à jour données</h1>
            <SaveDancerFormComponent id_dancer={id_dancer} dancer={dancer} />

        </>
    );
}
