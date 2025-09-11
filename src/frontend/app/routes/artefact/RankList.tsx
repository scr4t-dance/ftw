import React from 'react';

import { RoleItem, YanItem, type Artefact, type Bib, type DancerId, type DancerIdList, type HeatTargetJudgeArtefact, type PhaseId, type PhaseRanks, type Target, type TargetRank } from "@hookgen/model";
import { Link, useParams } from "react-router";
import { useGetApiPhaseId } from "@hookgen/phase/phase";
import { useQueries } from "@tanstack/react-query";
import { DancerCell } from '@routes/bib/BibList';
import { getGetApiDancerIdQueryOptions } from '~/hookgen/dancer/dancer';
import { useGetApiPhaseIdJudges } from '~/hookgen/judge/judge';
import { useGetApiPhaseIdRanking } from '~/hookgen/ranking/ranking';

const rank_list_list = {
    ranks: [
        [
            {
                ranking_type: "yan",
                target: { target_type: "single", target: 1, role: [RoleItem.Follower] } as Target,
                rank: 1,
                artefact_list: [{ artefact_type: "yan", artefact_data: [[YanItem.Yes]] }, { artefact_type: "yan", artefact_data: [[YanItem.Yes]] }],
                score: 10,
            },
            {
                ranking_type: "yan",
                target: { target_type: "single", target: 2, role: [RoleItem.Leader] } as Target,
                rank: 1,
                artefact_list: [{ artefact_type: "yan", artefact_data: [[YanItem.Yes]] }, { artefact_type: "yan", artefact_data: [[YanItem.Yes]] }],
                score: 10,
            },
        ]
    ]
} as PhaseRanks;

const iter_target_dancers = (t: Target) => t.target_type === "single"
    ? [t.target]
    : [t.follower, t.leader];

function ArtefactCell({ artefact }: { artefact: Artefact }) {

    return (
        <td>
            {artefact?.artefact_type === "yan" && (
                artefact.artefact_data.join('/')
            )}
            {artefact?.artefact_type === "ranking" && (
                artefact.artefact_data
            )}
        </td>
    );
}

function RankRow({ target_rank, index }: { target_rank: TargetRank, index: number }) {

    const dancer_list = iter_target_dancers(target_rank.target);

    return (
        <tr key={index}
            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
            <td>{target_rank.rank}</td>
            {target_rank.ranking_type === "yan" &&
                <td>{target_rank.score}</td>
            }
            <td>
                {dancer_list && dancer_list.map((i) => (
                    <DancerCell id_dancer={i} />
                ))}
            </td>
            {(target_rank.artefact_list ?? []).map((rank) => (
                <ArtefactCell artefact={rank} />
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

export function RankListComponent({ phase_id, judges, head_judge, rank_list_list }: { phase_id: PhaseId, judges: DancerIdList, head_judge: DancerId | undefined, rank_list_list: PhaseRanks }) {

    const all_judges: DancerId[] = judges.dancers.concat(head_judge ? [head_judge] : []);

    const judgeDataQueries = useQueries({
        queries: all_judges.map((dancerId) => ({
            ...getGetApiDancerIdQueryOptions(dancerId),
            enabled: true,
        })),
    });

    const isJudgesLoading = judgeDataQueries.some((query) => query.isLoading);
    const isJudgesError = judgeDataQueries.some((query) => query.isError);

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

    return (
        <table>
            <tbody>
                <tr>
                    <th>Rank</th>
                    <th>Score</th>
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
                {rank_list_list && rank_list_list.ranks.flat().map((target_rank, index) => {
                    return (
                        <RankRow
                            target_rank={target_rank}
                            index={index}
                        />
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

    const { data: _rank_list_list, isSuccess: isSuccessRank } = useGetApiPhaseIdRanking(id_phase_number);

    const { data: judgePanel, isSuccess: isSuccessJudges } = useGetApiPhaseIdJudges(id_phase_number);

    if (isLoading) return <div>Chargement...</div>;
    if (!phaseData) return null;
    //if (!isSuccessRank) return <div>Chargement des classements...</div>;
    if (!isSuccessJudges) return <div>Chargement des juges...</div>;

    return (
        <>
            <h1>Données simulées !!!!</h1>
            {judgePanel.panel_type === "single" && rank_list_list && rank_list_list.ranks &&
                <>
                    <h1>Followers</h1>
                    <RankListComponent
                        phase_id={id_phase_number}
                        judges={judgePanel.followers}
                        head_judge={judgePanel.head}
                        rank_list_list={{ranks:rank_list_list.ranks.map((u) => (u.filter((t) => t.target.target_type === "single" && t.target.role[0] === "Follower")))}}
                    />
                    <h1>Leaders</h1>
                    <RankListComponent
                        phase_id={id_phase_number}
                        judges={judgePanel.leaders}
                        head_judge={judgePanel.head}
                        rank_list_list={{ranks:rank_list_list.ranks.map((u) => (u.filter((t) => t.target.target_type === "single" && t.target.role[0] === "Leader")))}}
                    />
                </>
            }
            {judgePanel.panel_type === "couple" && rank_list_list && rank_list_list.ranks &&
                <>
                    <h1>Couples</h1>
                    <RankListComponent
                        phase_id={id_phase_number}
                        judges={judgePanel.couples}
                        head_judge={judgePanel.head}
                        rank_list_list={{ranks:rank_list_list.ranks.map((u) => (u.filter((t) => t.target.target_type === "couple")))}}
                    />
                </>
            }
        </>
    );
}
