import React from 'react';
import { Link, useLocation, useParams } from "react-router";

import { CategoryItem, RoleItem, type BibList, type Competition, type CompetitionId, type CompetitionIdList, type Dancer, type DancerCompetitionResults, type DancerCompetitionResultsList, type DancerCompetitionResultsResult, type DancerId, type Divisions, type RankingResults, type Role, type Target } from "@hookgen/model";
import { useGetApiDancerId, useGetApiDancerIdCompetitionHistory } from '@hookgen/dancer/dancer';
import { useQueries } from "@tanstack/react-query";
import { getGetApiCompIdQueryOptions } from "@hookgen/competition/competition";
import { Badge } from '@routes/dancer/DancerComponents';
import { useGetApiDancerIdResults } from '~/hookgen/results/results';
import { useGetApiEventId } from '~/hookgen/event/event';
import { formatDate } from '../event/EventComponents';

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

function getDivisionFromDancer(dancer: Dancer, role: Role) {
    const division_dancer: Record<RoleItem, Divisions> = {
        [RoleItem.Follower]: dancer.as_follower,
        [RoleItem.Leader]: dancer.as_leader,
    };

    return division_dancer[role[0]];
}


export function get_rang(ranking_result: DancerCompetitionResultsResult) {

    if (ranking_result.finals.result_type === "ranked") return String(ranking_result.finals.ranked) + "ème";
    if (ranking_result.finals.result_type === "present") return "Finaliste";
    if (ranking_result.semifinals.result_type === "present") return "Demifinaliste";

    return "";

}

function NonCompetitiveHistoryTable({ dancer_competition_results_list, competition_data }: { dancer_competition_results_list: DancerCompetitionResultsList, competition_data: Competition[] }) {

    const dancer_competition_results_list_per_category = groupByToMap(dancer_competition_results_list.results, (_, i) => competition_data[i].category[0]);
    const competition_data_per_category = groupByToMap(competition_data, (_, i) => competition_data[i].category[0]);

    return (
        <>
            <table>
                <thead>
                    <tr>
                        <th>Compétition</th>
                        <th>Date</th>
                        <th></th>
                        <th>Points</th>
                    </tr>
                </thead>
                <tbody>
                    {Array.from(dancer_competition_results_list_per_category.keys()).map((categoryItem) => (
                        <>
                            <tr>
                                <th colSpan={4}>{categoryItem}</th>
                            </tr>
                            {dancer_competition_results_list_per_category.get(categoryItem)?.map((dcr, index) => (

                                <tr>
                                    <NonCompetitiveHistoryRow dancer_competition_results={dcr} competition_data={competition_data_per_category.get(categoryItem)?.[index] as Competition} />
                                </tr>
                            ))}
                        </>
                    ))}
                </tbody>
            </table>
        </>
    );
}

function CompetitiveHistoryRow({ dancer_competition_results, competition_data }: { dancer_competition_results: DancerCompetitionResults, competition_data: Competition }) {

    const { data: dataEvent, isLoading, isSuccess } = useGetApiEventId(competition_data.event);
    if (isLoading) return (<td colSpan={4}>Loading...</td>);
    if (!isSuccess) return (<td colSpan={4}>Could not extract event data</td>);

    const location = useLocation();
    const url = location.pathname.includes("admin") ? "/admin/" : "/";

    return (
        <>
            <td>
                <Link to={`${url}events/${competition_data.event}/competitions/${dancer_competition_results.competition}`}>
                    {dataEvent.name} {competition_data.name}
                </Link>
            </td>
            <td>{formatDate(dataEvent.start_date)}</td>
            <td>{get_rang(dancer_competition_results.result)}</td>
            <td>{dancer_competition_results.points}</td>
        </>
    );

}

function NonCompetitiveHistoryRow({ dancer_competition_results, competition_data }: { dancer_competition_results: DancerCompetitionResults, competition_data: Competition }) {

    const { data: dataEvent, isLoading, isSuccess } = useGetApiEventId(competition_data.event);
    if (isLoading) return (<td colSpan={4}>Loading...</td>);
    if (!isSuccess) return (<td colSpan={4}>Could not extract event data</td>);

    const location = useLocation();
    const url = location.pathname.includes("admin") ? "/admin/" : "/";

    return (
        <>
            <td>
                <Link to={`${url}events/${competition_data.event}/competitions/${dancer_competition_results.competition}`}>
                    {dataEvent.name} {competition_data.name}
                </Link>
            </td>
            <td>{formatDate(dataEvent.start_date)}</td>
            <td>{competition_data.kind}</td>
            <td>{get_rang(dancer_competition_results.result)}</td>
        </>
    );

}

function CompetitiveHistoryTable({ dancer_competition_results_list, competition_data }: { dancer_competition_results_list: DancerCompetitionResultsList, competition_data: Competition[] }) {

    const dancer_competition_results_list_per_category = groupByToMap(dancer_competition_results_list.results, (_, i) => competition_data[i].category[0]);
    const competition_data_per_category = groupByToMap(competition_data, (_, i) => competition_data[i].category[0]);

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
                    {Array.from(dancer_competition_results_list_per_category.keys()).map((categoryItem) => (
                        <>
                            <tr>
                                <th colSpan={3}>{categoryItem}</th>
                                <th>
                                    Total=
                                    {dancer_competition_results_list_per_category.get(categoryItem)?.reduce((n, { points }) => n + points, 0)}
                                </th>
                            </tr>
                            {dancer_competition_results_list_per_category.get(categoryItem)?.map((dcr, index) => (

                                <tr>
                                    <CompetitiveHistoryRow dancer_competition_results={dcr} competition_data={competition_data_per_category.get(categoryItem)?.[index] as Competition} />
                                </tr>
                            ))}
                        </>
                    ))}
                </tbody>
            </table>
        </>
    );
}

function is_competitive(competition: Competition) {

    return ["Novice", "Intermediate", "Advanced"].includes(competition.category[0]) && competition.kind[0] === "Jack_and_Jill"
}

function BareCompetitionHistoryTable({ dancer_competition_results_list, competition_data }: { dancer_competition_results_list: DancerCompetitionResultsList, competition_data: Competition[] }) {

    const dcr_competitive = dancer_competition_results_list.results.filter((_, index) => is_competitive(competition_data[index]))
    const comp_competitive = competition_data.filter((_, index) => is_competitive(competition_data[index]))

    const dcr_noncompetitive = dancer_competition_results_list.results.filter((r, index) => !is_competitive(competition_data[index]))
    const comp_noncompetitive = competition_data.filter((r, index) => !is_competitive(competition_data[index]))

    return (
        <>
            <h2>SCR4T</h2>
            <CompetitiveHistoryTable dancer_competition_results_list={{ results: dcr_competitive }} competition_data={comp_competitive} />
            <h2>Non-SCR4T</h2>
            <NonCompetitiveHistoryTable dancer_competition_results_list={{ results: dcr_noncompetitive }} competition_data={comp_noncompetitive} />
        </>
    );
}


function InnerCompetitionHistoryTable({ id_dancer, dancer_competition_results_list, competition_data }: { id_dancer: DancerId, dancer_competition_results_list: DancerCompetitionResultsList, competition_data: Competition[] }) {

    const { data: dataDancer, isLoading, isError, error } = useGetApiDancerId(id_dancer);

    const competition_list_per_role = groupByToMap(dancer_competition_results_list.results, (r) => r.role[0]);
    const competition_data_per_role = groupByToMap(competition_data, (_, i) => dancer_competition_results_list.results[i].role[0]);

    if (isLoading) return <div>Chargement de la compétiteurice...</div>;
    if (isError) return <div>{error.message}</div>;

    return (
        <>
            {Array.from(competition_list_per_role.keys()).map((role) => (
                <>
                    <h2>
                        {role}
                        <Badge role={role.toString()} divisions={getDivisionFromDancer(dataDancer as Dancer, [role])} />
                    </h2>
                    <BareCompetitionHistoryTable
                        dancer_competition_results_list={{ results: competition_list_per_role.get(role) } as DancerCompetitionResultsList}
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
    const { data: dancer_competition_results_list, isLoading, isSuccess } = useGetApiDancerIdResults(id_dancer_number);

    const competitionDetailsQueries = useQueries({
        queries: (dancer_competition_results_list?.results ?? []).map((r) => ({
            ...getGetApiCompIdQueryOptions(r.competition),
            enabled: isSuccess,
        })),
    });


    if (isLoading) return null;
    if (!dancer_competition_results_list) return null;

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
            dancer_competition_results_list={dancer_competition_results_list}
            competition_data={competition_data} />
    )

}

export default DancerCompetitionHistory;