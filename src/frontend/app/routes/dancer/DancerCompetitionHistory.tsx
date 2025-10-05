import React from 'react';
import { Link, useLocation, useParams } from "react-router";

import { CategoryItem, RoleItem, type BibList, type Competition, type CompetitionId, type CompetitionIdList, type Dancer, type DancerId, type Divisions, type Role, type Target } from "@hookgen/model";
import { useGetApiDancerId, useGetApiDancerIdCompetitionHistory } from '@hookgen/dancer/dancer';
import { useQueries } from "@tanstack/react-query";
import { getGetApiCompIdQueryOptions } from "@hookgen/competition/competition";
import { getGetApiCompIdBibsQueryOptions } from '~/hookgen/bib/bib';
import { Badge } from '@routes/dancer/DancerComponents';

// https://stackoverflow.com/questions/14446511/most-efficient-method-to-groupby-on-an-array-of-objects
const groupByToMap = <T, Q>(array: T[], predicate: (value: T, index: number, array: T[]) => Q) =>
    array.reduce((map, value, index, array) => {
        const key = predicate(value, index, array);
        map.get(key)?.push(value) ?? map.set(key, [value]);
        return map;
    }, new Map<Q, T[]>());


function dancerArrayFromTarget(t: Target): DancerId[] {
    return t.target_type === "single"
        ? [t.target]
        : [t.follower, t.leader]
}

function getRoleFromTarget(target: Target, id_dancer: DancerId) {
    if (!dancerArrayFromTarget(target).includes(id_dancer)) return undefined;

    if (target.target_type === "single") {
        return target.role;
    }

    return target.follower === id_dancer ? [RoleItem.Follower] : [RoleItem.Leader];
}

function getDivisionFromDancer(dancer:Dancer, role:Role) {
    const division_dancer: Record<RoleItem, Divisions> = {
        [RoleItem.Follower]: dancer.as_follower,
        [RoleItem.Leader]: dancer.as_leader,
    };

    return division_dancer[role[0]];
}




function BareCompetitionHistoryTable({ competition_list, competition_data }: { competition_list: CompetitionIdList, competition_data: Competition[] }) {

    const competition_list_per_category = groupByToMap(competition_list.competitions as CompetitionId[], (_, i) => competition_data[i].category[0]);
    const competition_data_per_category = groupByToMap(competition_data, (_, i) => competition_data[i].category[0]);

    const location = useLocation();
    const url = location.pathname.includes("admin") ? "/admin/" : "/";

    return (
        <>
            <table>
                <thead>
                    <tr>
                        <th>Compétition</th>
                        <th>Date</th>
                        <th>Rang</th>
                        <th>Points</th>
                    </tr>
                </thead>
                <tbody>
                    {Array.from(competition_list_per_category.keys()).map((categoryItem) => (
                        <>
                            <tr>
                                <th colSpan={3}>{categoryItem}</th>
                                <th>TODO</th>
                            </tr>
                            {competition_data_per_category.get(categoryItem)?.map((competition, index) => (

                                <tr>
                                    <td>
                                        <Link to={`${url}events/${competition.event}/competitions/${competition_list_per_category.get(categoryItem)?.[index]}`}>
                                            {competition.name}
                                        </Link>
                                    </td>
                                    <td>{competition.kind}</td>
                                    <td>TODO</td>
                                    <td>TODO</td>
                                </tr>
                            ))}
                        </>
                    ))}
                </tbody>
            </table>
        </>
    );
}


function InnerCompetitionHistoryTable({ id_dancer, competition_list, competition_data }: { id_dancer: DancerId, competition_list: CompetitionIdList, competition_data: Competition[] }) {

    const { data: dataDancer, isLoading, isError, error } = useGetApiDancerId(id_dancer);

    const bibQueries = useQueries({
        queries: (competition_list?.competitions ?? []).map((competitionId) => ({
            ...getGetApiCompIdBibsQueryOptions(competitionId),
        })),
    });

    if (isLoading) return <div>Chargement de la compétiteurice...</div>;
    if (isError) return <div>Erreur: {error.message}</div>;

    const isDetailsLoading = bibQueries.some((query) => query.isLoading);
    const isDetailsError = bibQueries.some((query) => query.isError);

    if (isDetailsLoading) return <div>Loading competition details...</div>;
    if (isDetailsError) return (
        <div>
            Error loading competition details
            {
                bibQueries.map((query) => {
                    return (<p>{query.error?.message}</p>);
                })
            }
        </div>);

    const bib_data = bibQueries.map((q) => (q?.data as BibList)?.bibs.filter((b) => dancerArrayFromTarget(b.target).includes(id_dancer)))
    const role_data = bib_data.map((bib_list) => getRoleFromTarget(bib_list[0].target, id_dancer) as Role);

    const competition_list_per_role = groupByToMap(competition_list.competitions as CompetitionId[], (_, i) => role_data[i][0]);
    const competition_data_per_role = groupByToMap(competition_data, (_, i) => role_data[i][0]);

    return (
        <>
            {Array.from(competition_list_per_role.keys()).map((role) => (
                <>
                    <h2>
                        {role}
                        <Badge role={role.toString()} divisions={getDivisionFromDancer(dataDancer as Dancer, [role])} />
                    </h2>
                    <BareCompetitionHistoryTable
                        competition_list={{ competitions: competition_list_per_role.get(role) as CompetitionId[]}}
                        competition_data={competition_data_per_role.get(role) as Competition[]}
                    />
                </>

            ))}
        </>
    );
}

function DancerCompetitionHistory() {

    let { id_dancer } = useParams();
    let id_dancer_number = Number(id_dancer) as DancerId;

    /* todo regarder les résultats */
    const { data: competition_id_list, isLoading, isSuccess } = useGetApiDancerIdCompetitionHistory(id_dancer_number);

    const competitionDetailsQueries = useQueries({
        queries: (competition_id_list?.competitions ?? []).map((competitionId) => ({
            ...getGetApiCompIdQueryOptions(competitionId),
            enabled: isSuccess,
        })),
    });


    if (isLoading) return null;
    if (!competition_id_list) return null;

    const isDetailsLoading = competitionDetailsQueries.some((query) => query.isLoading);
    const isDetailsError = competitionDetailsQueries.some((query) => query.isError);

    if (isDetailsLoading) return <div>Loading competition details...</div>;
    if (isDetailsError) return (
        <div>
            Error loading competition details
            {
                competitionDetailsQueries.map((query) => {
                    return (<p>{query.error?.message}</p>);
                })
            }
        </div>);


    const competition_data = competitionDetailsQueries.filter((query) => query.isSuccess).map((q) => q.data);
    return (
        <InnerCompetitionHistoryTable
            id_dancer={id_dancer_number}
            competition_list={competition_id_list}
            competition_data={competition_data} />
    )

}

export default DancerCompetitionHistory;