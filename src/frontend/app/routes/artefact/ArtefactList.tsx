import React, { useEffect } from 'react';

import type { Bib, CompetitionId, DancerId, DancerIdList, HeatTargetJudgeArtefact, HeatTargetJudgeArtefactArray, Phase, PhaseId, Target } from "@hookgen/model";
import { Link, useParams } from "react-router";
import { useGetApiPhaseId } from "@hookgen/phase/phase";
import { useGetApiPhaseIdSinglesHeats } from "~/hookgen/heat/heat";
import { useQueries } from "@tanstack/react-query";
import { DancerCell } from '@routes/bib/BibList';
import { useGetApiCompIdBibs } from '~/hookgen/bib/bib';
import { getGetApiDancerIdQueryOptions } from '~/hookgen/dancer/dancer';
import { getGetApiPhaseIdArtefactJudgeIdJudgeQueryOptions } from '~/hookgen/artefact/artefact';

const judges: DancerIdList = { dancers: [1] };
const head_judge: DancerId = 1;

const iter_target_dancers = (t: Target) => t.target_type === "single"
    ? [t.target]
    : [t.follower, t.leader];

function ArtefactCell({ htja }: { htja: HeatTargetJudgeArtefact }) {

    return (
        <td>
            {htja?.artefact?.toString()}
        </td>
    );
}

function ArtefactRow({ htja_array, index }: { htja_array: HeatTargetJudgeArtefactArray, index: number }) {
    const artefacts = htja_array?.artefacts ?? [];

    console.log(htja_array);
    if (!artefacts || !artefacts[0]) {
        return (
            <tr key={index} className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
                <td>No HTJA data</td>
            </tr>
        );
    }

    const target = artefacts[0].heat_target_judge.target;
    const dancer_list = iter_target_dancers(target);

    return (
        <tr key={`${artefacts[0].heat_target_judge.heat_number}-${artefacts[0].heat_target_judge.target}`}
            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
            <td>
                {dancer_list && dancer_list.map((i) => (
                    <DancerCell id_dancer={i} />
                ))}
            </td>
            {htja_array.artefacts.map((htja) => (
                <ArtefactCell htja={htja} />
            ))}
        </tr >
    );
}

export function ArtefactListComponent({ phase_id, judges, head_judge, heat_number, bib_list }: { phase_id: PhaseId, judges: DancerIdList, head_judge: DancerId, heat_number: number, bib_list: Array<Bib> }) {

    const all_judges: DancerId[] = judges.dancers.concat([head_judge]);

    const judgeDataQueries = useQueries({
        queries: all_judges.map((dancerId) => ({
            ...getGetApiDancerIdQueryOptions(dancerId),
            enabled: true,
        })),
    });

    const artefactDataQueries = useQueries({
        queries: all_judges.map((judge_id) => ({
            ...getGetApiPhaseIdArtefactJudgeIdJudgeQueryOptions(phase_id, judge_id),
            enabled: true,
        })),
    });

    const isJudgesLoading = judgeDataQueries.some((query) => query.isLoading);
    const isJudgesError = judgeDataQueries.some((query) => query.isError);
    const isArtefactsLoading = artefactDataQueries.some((query) => query.isLoading);
    const isArtefactsError = artefactDataQueries.some((query) => query.isError);

    if (isJudgesLoading) return <div>Loading judges details...</div>;
    if (isJudgesError) return (
        <div>
            Error loading judges data
            {
                judgeDataQueries.map((query) => {
                    return (<p>{query.error?.message}</p>);
                })
            }
        </div>);
    if (isArtefactsLoading) return <div>Loading artefact details...</div>;
    if (isArtefactsError) return (
        <div>
            Error loading artefacts data
            {
                artefactDataQueries.map((query) => {
                    return (<p>{query.error?.message}</p>);
                })
            }
        </div>);

    const target_artefacts = bib_list.map((bib) => {
        const htja_list = artefactDataQueries.flatMap((artefactQuery) => (
            artefactQuery.data?.artefacts.filter(
                (htja) => (htja.heat_target_judge.target === bib.target &&
                    htja.heat_target_judge.heat_number === heat_number))
        )) as HeatTargetJudgeArtefact[];
        const htja_array: HeatTargetJudgeArtefactArray = { artefacts: htja_list };
        return htja_array;
    });

    return (
        <table>
            <tbody>
                <tr>
                    <th>Target</th>
                    {judgeDataQueries.map((judgeQuery, index) => {
                        const judgeId = all_judges[index];
                        const judgeData = judgeQuery.data;

                        if (!judgeData) return null;

                        return (
                            <th>
                                {index === judges.dancers.length && "Head "}
                                <Link to={`/phases/${phase_id}/artefacts/judge/${judgeId}`}>
                                    {judgeData.first_name + " " + judgeData.last_name}
                                </Link>
                            </th>
                        );
                    })}
                </tr>
                {target_artefacts && target_artefacts.map((htja_array, index) => {
                    return (
                        <> {htja_array.artefacts &&
                            <ArtefactRow
                                htja_array={htja_array}
                                index={index}
                            />
                        }
                        </>
                    );
                })}
            </tbody>
        </table>
    );
}



export default function ArtefactList() {

    let { id_phase } = useParams();
    let id_phase_number = Number(id_phase) as PhaseId;
    const { data: phaseData, isLoading } = useGetApiPhaseId(id_phase_number);

    const { data: heat_list, isSuccess: isSuccessHeats } = useGetApiPhaseIdSinglesHeats(id_phase_number);

    const { data: dataBibs, isSuccess: isSuccessBibs } = useGetApiCompIdBibs(phaseData?.competition as CompetitionId);

    if (isLoading) return <div>Chargement...</div>;
    if (!phaseData) return null;
    if (!isSuccessBibs) return <div>Chargement des bibs...</div>;
    if (!isSuccessHeats) return <div>Chargement des heats...</div>;

    //const followers = heat_list.heats.flatMap(v => (v.followers.flatMap(u => iter_target_dancers(u))));
    //const leaders = heat_list.heats.flatMap(v => (v.leaders.flatMap(u => u.target)));
    const get_bibs = (dancer_list: DancerId[]) => dataBibs?.bibs.filter(b => iter_target_dancers(b.target).map(dancer => dancer_list?.includes(dancer)).includes(true));

    return (
        <>
            {heat_list && heat_list.heats && heat_list.heats.map((v, heat_minus_one) => (
                <>
                    <h1>Heat {heat_minus_one + 1} / {heat_list.heats.length}</h1>
                    <p>Followers</p>
                    <ArtefactListComponent
                        phase_id={id_phase_number}
                        judges={judges}
                        head_judge={head_judge}
                        heat_number={heat_minus_one}
                        bib_list={get_bibs(v.followers.flatMap(u => iter_target_dancers(u)))}
                    />
                    <p>Leaders</p>
                    <ArtefactListComponent
                        phase_id={id_phase_number}
                        judges={judges}
                        head_judge={head_judge}
                        heat_number={heat_minus_one}
                        bib_list={get_bibs(v.leaders.flatMap(u => iter_target_dancers(u)))}
                    />
                </>
            ))}

        </>
    );
}
