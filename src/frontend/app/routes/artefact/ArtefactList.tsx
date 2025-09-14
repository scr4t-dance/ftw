import React, { useState } from 'react';

import type { Bib, CompetitionId, DancerId, DancerIdList, HeatTargetJudgeArtefact, HeatTargetJudgeArtefactArray, Phase, PhaseId, Target } from "@hookgen/model";
import { Link, useParams } from "react-router";
import { useGetApiPhaseId } from "@hookgen/phase/phase";
import { useGetApiPhaseIdHeats } from "~/hookgen/heat/heat";
import { useQueries } from "@tanstack/react-query";
import { DancerCell } from '@routes/bib/BibList';
import { useGetApiCompIdBibs } from '~/hookgen/bib/bib';
import { getGetApiDancerIdQueryOptions } from '~/hookgen/dancer/dancer';
import { getGetApiPhaseIdArtefactJudgeIdJudgeQueryOptions } from '~/hookgen/artefact/artefact';
import { useGetApiPhaseIdJudges } from '~/hookgen/judge/judge';

const iter_target_dancers = (t: Target) => t.target_type === "single"
    ? [t.target]
    : [t.follower, t.leader];

function ArtefactCell({ htja }: { htja: HeatTargetJudgeArtefact }) {

    return (
        <td>
            {htja?.artefact?.artefact_type === "yan" && (
                htja.artefact.artefact_data.join('/')
            )}
            {htja?.artefact?.artefact_type === "ranking" && (
                htja.artefact.artefact_data
            )}
        </td>
    );
}

function ArtefactRow({ htja_array, index }: { htja_array: HeatTargetJudgeArtefactArray, index: number }) {
    const artefacts = htja_array?.artefacts ?? [];

    if (!artefacts || !artefacts[0]) {
        return (
            <tr className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
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

function matchHeatBib(htja: HeatTargetJudgeArtefact, bib: Bib, heat_number: number | undefined) {
    if (heat_number === undefined) {
        return JSON.stringify(htja.heat_target_judge.target) === JSON.stringify(bib.target);
    }

    return (
        JSON.stringify(htja.heat_target_judge.target) === JSON.stringify(bib.target)
        && (htja.heat_target_judge.heat_number === heat_number));
}

export function ArtefactListComponent({ phase_id, judges, head_judge, heat_number, bib_list }: { phase_id: PhaseId, judges: DancerIdList, head_judge: DancerId | undefined, heat_number: number | undefined, bib_list: Array<Bib> }) {

    const all_judges: DancerId[] = judges.dancers.concat(head_judge ? [head_judge] : []);

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
    const isArtefactsSuccess = artefactDataQueries.every((query) => query.isSuccess);
    const isArtefactsError = artefactDataQueries.some((query) => query.isError);

    if (isJudgesLoading) return <div>Loading judges details...</div>;
    if (isArtefactsLoading) return <div>Loading artefacts details...</div>;
    if (isJudgesError) return (
        <div>
            Error loading judges data
            {
                judgeDataQueries.map((query) => {
                    return (<p>{query.error?.message}</p>);
                })
            }
        </div>);
    if (isArtefactsError) return (
        <div>
            Error loading artefacts data
            {
                artefactDataQueries.map((query) => {
                    return (<p>{query.error?.message}</p>);
                })
            }
        </div>);
    if (!isArtefactsSuccess) return <div>Failed loading artefact details...</div>;

    const htjaData = artefactDataQueries.map((artefactQuery) => (artefactQuery.data as HeatTargetJudgeArtefactArray));
    //console.log("htjaData", htjaData);
    const target_artefacts = bib_list.map((bib) => {
        const htja_list: HeatTargetJudgeArtefact[] = htjaData.map((htja_judge_array) => (
            htja_judge_array.artefacts.filter((htja) => matchHeatBib(htja, bib, heat_number))[0]
        ));
        const htja_array: HeatTargetJudgeArtefactArray = { artefacts: htja_list };
        return htja_array;
    });

    //console.log(htjaData[1].artefacts[3].heat_target_judge.target);
    //console.log(bib_list[0].target);
    //console.log(bib_list[0].target == htjaData[1].artefacts[3].heat_target_judge.target);
    //console.log("judges", judges, "htjaData", htjaData, "target_artefacts all judges", target_artefacts, "bib_list", bib_list);

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

    const [isHeatView, setHeatView] = useState(false);

    const { data: heat_list, isSuccess: isSuccessHeats } = useGetApiPhaseIdHeats(id_phase_number);

    const { data: dataBibs, isSuccess: isSuccessBibs } = useGetApiCompIdBibs(phaseData?.competition as CompetitionId);

    const { data: judgePanel, isSuccess: isSuccessJudges } = useGetApiPhaseIdJudges(id_phase_number);

    if (isLoading) return <div>Chargement...</div>;
    if (!phaseData) return null;
    if (!isSuccessBibs) return <div>Chargement des bibs...</div>;
    if (!isSuccessHeats) return <div>Chargement des heats...</div>;
    if (!isSuccessJudges) return <div>Chargement des juges...</div>;
    if (heat_list.heat_type !== judgePanel.panel_type) return <div>Error Panel and Heats do not match</div>

    const targets = heat_list.heat_type === "single" ? {
        followers: heat_list.heats.flatMap(v => (v.followers)),
        leaders: heat_list.heats.flatMap(v => (v.leaders)),
    } : (heat_list.heat_type === "couple" ? {
        couples: heat_list.heats.flatMap(v => (v.couples))
    } : {});
    const get_bibs = (dancer_list: DancerId[]) => dataBibs?.bibs.filter(b => iter_target_dancers(b.target).map(dancer => dancer_list?.includes(dancer)).includes(true));

    return (
        <>
            <button type='button' onClick={() => setHeatView(!isHeatView)}>Change heat view</button>
            {judgePanel.panel_type === "single" && !isHeatView && heat_list && heat_list.heats &&
                <>
                    <h1>Followers</h1>
                    <ArtefactListComponent
                        phase_id={id_phase_number}
                        judges={judgePanel.followers}
                        head_judge={judgePanel.head}
                        heat_number={undefined}
                        bib_list={get_bibs((targets.followers ?? []).flatMap(u => iter_target_dancers(u)))}
                    />
                    <h1>Leaders</h1>
                    <ArtefactListComponent
                        phase_id={id_phase_number}
                        judges={judgePanel.leaders}
                        head_judge={judgePanel.head}
                        heat_number={undefined}
                        bib_list={get_bibs((targets.leaders ?? []).flatMap(u => iter_target_dancers(u)))}
                    />
                </>
            }
            {judgePanel.panel_type === "single" && heat_list.heat_type === "single"
                && isHeatView && heat_list && heat_list.heats && heat_list.heats.map((v, heat_minus_one) => (
                    <>
                        <h1>Heat {heat_minus_one + 1} / {heat_list.heats.length}</h1>
                        <h2>Followers</h2>
                        <ArtefactListComponent
                            phase_id={id_phase_number}
                            judges={judgePanel.followers}
                            head_judge={judgePanel.head}
                            heat_number={heat_minus_one}
                            bib_list={get_bibs(v.followers.flatMap(u => iter_target_dancers(u)))}
                        />
                        <h2>Leaders</h2>
                        <ArtefactListComponent
                            phase_id={id_phase_number}
                            judges={judgePanel.leaders}
                            head_judge={judgePanel.head}
                            heat_number={heat_minus_one}
                            bib_list={get_bibs(v.leaders.flatMap(u => iter_target_dancers(u)))}
                        />
                    </>
                ))}
            {judgePanel.panel_type === "couple" && heat_list.heat_type === "couple"
                && !isHeatView && heat_list && heat_list.heats &&
                <>
                    <h1>Couples</h1>
                    <ArtefactListComponent
                        phase_id={id_phase_number}
                        judges={judgePanel.couples}
                        head_judge={judgePanel.head}
                        heat_number={undefined}
                        bib_list={get_bibs((targets.couples ?? []).flatMap(u => iter_target_dancers(u)))}
                    />
                </>
            }
            {judgePanel.panel_type === "couple" && heat_list.heat_type === "couple"
                && isHeatView && heat_list && heat_list.heats && heat_list.heats.map((v, heat_minus_one) => (
                    <>
                        <h1>Heat {heat_minus_one + 1} / {heat_list.heats.length}</h1>
                        <h2>Couples</h2>
                        <ArtefactListComponent
                            phase_id={id_phase_number}
                            judges={judgePanel.couples}
                            head_judge={judgePanel.head}
                            heat_number={heat_minus_one}
                            bib_list={get_bibs(v.couples.flatMap(u => iter_target_dancers(u)))}
                        />
                    </>
                ))}
        </>
    );
}
