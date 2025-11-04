import React, { useState } from 'react';

import {
    RoleItem, YanItem, type Artefact, type Dancer, type DancerId, type DancerIdList, type HeatTargetJudgeArtefactArray, type OneRanking, type Panel, type PhaseId,
    type PhaseRanking, type PhaseRankingSingles, type Target, type TargetRank
} from "@hookgen/model";
import { Link, useParams } from "react-router";
import { useGetApiPhaseId } from "@hookgen/phase/phase";
import { useQueries } from "@tanstack/react-query";
import { dancerArrayFromTarget, DancerCell } from '@routes/bib/BibComponents';
import { getGetApiDancerIdQueryOptions } from '~/hookgen/dancer/dancer';
import { useGetApiPhaseIdJudges } from '~/hookgen/judge/judge';
import { useGetApiPhaseIdRanking } from '~/hookgen/ranking/ranking';
import NextPhaseForm from '@routes/artefact/NextPhaseForm';
import { getGetApiPhaseIdArtefactJudgeIdJudgeQueryOptions } from '~/hookgen/artefact/artefact';
import { ArtefactCell, transposeJudgeTargetArtefacts } from './ArtefactComponents';

const yan_rank_list_list = {
    target_type: "single",
    followers: {
        ranks: [
            {
                ranking_type: "yan",
                target: { target_type: "single", target: 1, role: [RoleItem.Follower] } as Target,
                rank: 1,
                //artefact_list: [{ artefact_type: "yan", artefact_data: [[YanItem.Yes]] }, { artefact_type: "yan", artefact_data: [[YanItem.Yes]] }],
                score: 10,
            },
        ]
    },
    leaders: {
        ranks: [
            {
                ranking_type: "yan",
                target: { target_type: "single", target: 2, role: [RoleItem.Leader] } as Target,
                rank: 1,
                //artefact_list: [{ artefact_type: "yan", artefact_data: [[YanItem.Yes]] }, { artefact_type: "yan", artefact_data: [[YanItem.Yes]] }],
                score: 10,
            },
        ]
    }
} as PhaseRankingSingles;


const rpss_rank_list_list: PhaseRanking = {
    target_type: "single",
    followers: {
        ranks: [
            {
                ranking_type: "rpss",
                target: { target_type: "single", target: 1, role: [RoleItem.Follower] } as Target,
                rank: 1,
                //artefact_list: [{ artefact_type: "ranking", artefact_data: 1 }, { artefact_type: "ranking", artefact_data: 1 }],
                ranking_details: ["+1", "=2"]
            } satisfies TargetRank,
        ]
    },
    leaders: {
        ranks: [
            {
                ranking_type: "rpss",
                target: { target_type: "single", target: 2, role: [RoleItem.Leader] } as Target,
                rank: 1,
                //artefact_list: [{ artefact_type: "ranking", artefact_data: 1 }, { artefact_type: "ranking", artefact_data: 1 }],
                ranking_details: ["+1", "=2"]
            } satisfies TargetRank,
        ]
    },
} satisfies PhaseRanking;


function RankRow({ target_rank, all_judges, htjaArray }: { target_rank: TargetRank, all_judges: DancerId[], htjaArray: HeatTargetJudgeArtefactArray }) {

    const dancer_list = dancerArrayFromTarget(target_rank.target);
    const artefactArray = all_judges
        .map((i) => htjaArray.artefacts.find(htja => htja?.heat_target_judge.judge === i));

    return (
        <>
            <td>{target_rank.rank}</td>
            {target_rank.ranking_type === "yan" &&
                <td>{target_rank.score}</td>
            }
            <td>
                {dancer_list && dancer_list.map((i) => (
                    <DancerCell id_dancer={i} />
                ))}
            </td>
            {artefactArray.map((htja, index) => {
                if (htja)
                    return (
                        <td className={index === 0 ? "inner-vertical-line" : ""}>
                            <ArtefactCell htja={htja} />
                        </td>
                    );

                return (<td></td>)
            }
            )}
            {target_rank.ranking_type === "rpss" &&
                <td className='inner-vertical-line'>{target_rank.rank}</td>
            }
            {target_rank.ranking_type === "rpss" &&
                target_rank.ranking_details.map((s, index) => (
                    <td className={index === 0 ? "inner-vertical-line" : ""}>{s}</td>
                ))
            }
            {target_rank.ranking_type === "rpss" && // head judge have no ranking_details
                <td></td>
            }
        </>
    );
}

type OneRankListTableProps = {
    phase_id: PhaseId,
    judges: DancerIdList,
    head_judge: DancerId | undefined,
    oneRanking: OneRanking,
    treshold: number | undefined,
};

function JudgeHeadCell({ judgeId, judgeData, isHead }: { judgeId: DancerId, judgeData: Dancer, isHead: boolean }) {

    if (!judgeData) return null;
    return (
        <th>
            {isHead && "Head "}
            <Link to={`../artefacts/judge/${judgeId}`}>
                {judgeData.first_name + " " + judgeData.last_name}
            </Link>
        </th>
    );
}

function OneRankListTable({ phase_id, judges, head_judge, oneRanking, treshold }: OneRankListTableProps) {

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
    const bibTargets = oneRanking.ranks.map(b => b.target);
    //console.log("htjaData", htjaData);
    const target_artefacts = transposeJudgeTargetArtefacts(bibTargets, htjaData);

    const first_target_rank = oneRanking.ranks[0];

    return (
        <table className="large-table rank_table">
            <colgroup>
                <col />
                {first_target_rank.ranking_type === "yan" &&
                    <col />
                }
                <col />
                <col span={all_judges.length} />
                {first_target_rank.ranking_type === "rpss" &&
                    <>
                        <col />
                        <col span={judges.dancers.length} />
                    </>
                }
            </colgroup>
            <tbody>
                <tr>
                    <th />
                    {first_target_rank.ranking_type === "yan" &&
                        <th />
                    }
                    <th />
                    <th colSpan={all_judges.length}>Judges Rankings</th>
                    {first_target_rank.ranking_type === "rpss" &&
                        <>
                            <th />
                            <th colSpan={judges.dancers.length}>Relative Placements</th>
                        </>
                    }
                </tr>
                <tr>
                    <th>Rank</th>
                    {first_target_rank.ranking_type === "yan" &&
                        <>
                            <th>Score</th>
                        </>
                    }
                    <th>Target</th>
                    {judgeDataQueries.map((judgeQuery, index) => (
                        <JudgeHeadCell judgeId={all_judges[index]} judgeData={judgeQuery.data as Dancer} isHead={index === judges.dancers.length - 1} />
                    ))}
                    {first_target_rank.ranking_type === "rpss" &&
                        <>
                            <th>Rank</th>
                            {judgeDataQueries.map((judgeQuery, index) => (
                                <JudgeHeadCell judgeId={all_judges[index]} judgeData={judgeQuery.data as Dancer} isHead={index === judges.dancers.length - 1} />
                            ))}
                        </>
                    }
                </tr>
                {oneRanking && oneRanking.ranks.map((target_rank, index) => {
                    return (
                        <tr key={index}
                            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
                            <RankRow
                                target_rank={target_rank}
                                all_judges={all_judges}
                                htjaArray={target_artefacts[index]}
                            />
                        </tr>
                    );
                })}
            </tbody>
        </table>
    );
}

type RankListTableProps = {
    phase_id: PhaseId,
    judgePanel: Panel,
    rank_list_list: PhaseRanking,
    treshold: number | undefined,
};

function RankListTable({ phase_id, judgePanel, rank_list_list, treshold }: RankListTableProps) {

    return (
        <>
            {judgePanel.panel_type === "single" && rank_list_list.target_type === "single" &&
                <>
                    <h3>Followers</h3>
                    <OneRankListTable
                        phase_id={phase_id}
                        judges={judgePanel.followers}
                        head_judge={judgePanel.head}
                        oneRanking={rank_list_list.followers}
                        treshold={treshold}
                    />
                    <h3>Leaders</h3>
                    <OneRankListTable
                        phase_id={phase_id}
                        judges={judgePanel.leaders}
                        head_judge={judgePanel.head}
                        oneRanking={rank_list_list.leaders}
                        treshold={treshold}
                    />
                </>
            }

            {judgePanel.panel_type === "couple" && rank_list_list.target_type === "couple" &&
                <>
                    <h3>Couples</h3>
                    <OneRankListTable
                        phase_id={phase_id}
                        judges={judgePanel.couples}
                        head_judge={judgePanel.head}
                        oneRanking={rank_list_list.couples}
                        treshold={treshold}
                    />
                </>
            }
        </>
    );
}

function RankListComponent({ id_phase, treshold }: { id_phase: PhaseId, treshold: number | undefined }) {

    const { data: phaseData, isLoading } = useGetApiPhaseId(id_phase);

    const { data: rank_list_list, isLoading: isLoadingRank, isSuccess: isSuccessRank, isError: isErrorRank, error: errorRank } = useGetApiPhaseIdRanking(id_phase);

    const { data: judgePanel, isSuccess: isSuccessJudges } = useGetApiPhaseIdJudges(id_phase);

    if (isLoading) return <div>Chargement...</div>;
    if (!phaseData) return null;
    if (isLoadingRank) return <div>Chargement des classements...</div>;
    if (isErrorRank) return <div>Erreur lors du chargement des classements: {errorRank.message ?? ""}</div>;
    if (!isSuccessRank) return <div>Classements non chargés...</div>;
    if (!isSuccessJudges) return <div>Chargement des juges...</div>;

    return (
        <>
            <RankListTable phase_id={id_phase}
                judgePanel={judgePanel}
                rank_list_list={rank_list_list as PhaseRanking}
                treshold={treshold}
            />
        </>
    );

}


function DebugRankListComponent({ id_phase, treshold, debug }: { id_phase: PhaseId, treshold: number | undefined, debug: String | undefined }) {

    const { data: phaseData, isLoading } = useGetApiPhaseId(id_phase);

    const { data: _rank_list_list, isSuccess: isSuccessRank } = useGetApiPhaseIdRanking(id_phase);

    const { data: judgePanel, isSuccess: isSuccessJudges } = useGetApiPhaseIdJudges(id_phase);

    if (isLoading) return <div>Chargement...</div>;
    if (!phaseData) return null;
    // uncomment below when API works
    //if (!isSuccessRank) return <div>Chargement des classements...</div>;
    if (!isSuccessJudges) return <div>Chargement des juges...</div>;


    const rank_list_list = (debug === undefined) ? _rank_list_list : (
        debug === "yan" ? yan_rank_list_list : rpss_rank_list_list
    );

    return (
        <>
            <RankListTable phase_id={id_phase}
                judgePanel={judgePanel}
                rank_list_list={rank_list_list as PhaseRanking}
                treshold={treshold}
            />
        </>
    );

}

export default function RankList() {

    let { id_phase } = useParams();
    let id_phase_number = Number(id_phase) as PhaseId;

    const [treshold, setTreshold] = useState<number>();

    return (
        <>
            <NextPhaseForm id_phase={id_phase_number} treshold_callback={setTreshold} />
            <h1>Données simulées YAN !!!!</h1>
            <DebugRankListComponent id_phase={id_phase_number} treshold={treshold} debug={"yan"} />
            <h1>Données simulées RPSS !!!!</h1>
            <DebugRankListComponent id_phase={id_phase_number} treshold={treshold} debug={"rpss"} />
            <h1>Données Phase !!!!!</h1>
            <RankListComponent id_phase={id_phase_number} treshold={treshold} />
        </>
    );
}
