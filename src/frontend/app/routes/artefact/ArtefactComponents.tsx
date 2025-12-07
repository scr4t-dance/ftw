import React, { useState } from 'react';

import type {
    Bib, BibList, CoupleTarget, DancerId, DancerIdList, HeatsArray, HeatTargetJudgeArtefact,
    HeatTargetJudgeArtefactArray, Panel, PhaseId,
    Target,
} from "@hookgen/model";
import { Link, } from "react-router";
import { useQueries } from "@tanstack/react-query";
import { dancerArrayFromTarget, DancerCell } from '@routes/bib/BibComponents';
import { getGetApiDancerIdQueryOptions } from '@hookgen/dancer/dancer';
import { getGetApiPhaseIdArtefactJudgeIdJudgeQueryOptions } from '@hookgen/artefact/artefact';

function matchTarget(t1: Target, t2: Target) {
    return JSON.stringify(t1) === JSON.stringify(t2);
}

export function transposeJudgeTargetArtefacts(targetArray: Target[], judgeHTJAArray: HeatTargetJudgeArtefactArray[]) {

    const target_artefacts = targetArray.map((target) => {
        const htja_list: HeatTargetJudgeArtefact[] = judgeHTJAArray.map((htja_judge_array) => (
            htja_judge_array.artefacts.filter((htja) => matchTarget(htja.heat_target_judge.target, target))[0]
        ));
        const htja_array: HeatTargetJudgeArtefactArray = { artefacts: htja_list };
        return htja_array;
    });

    return target_artefacts;

}

export function ArtefactCell({ htja }: { htja: HeatTargetJudgeArtefact }) {

    return (
        <>
            {htja?.artefact?.artefact_type === "yan" && (
                htja.artefact.artefact_data.join('/')
            )}
            {htja?.artefact?.artefact_type === "ranking" && (
                htja.artefact.artefact_data
            )}
        </>
    );
}

function ArtefactRow({ htja_array }: { htja_array: HeatTargetJudgeArtefactArray }) {
    const artefacts = htja_array?.artefacts ?? [];

    if (!artefacts || !artefacts[0]) {
        return (
            <td>No HTJA data</td>
        );
    }

    const target = artefacts[0].heat_target_judge.target;
    const dancer_list = dancerArrayFromTarget(target);

    return (
        <>
            <td>
                {dancer_list && dancer_list.map((i) => (
                    <p>
                        <DancerCell id_dancer={i} />
                    </p>
                ))}
            </td>
            {htja_array.artefacts.map((htja, index) => (
                <td className={index === 0 ? "inner-vertical-line" : ""}>
                    <ArtefactCell htja={htja} />
                </td>
            ))}
        </>
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

type ArtefactTableArrayComponentProps = {
    phase_id: PhaseId,
    judges: DancerIdList,
    head_judge: DancerId | undefined,
    heat_number: number | undefined,
    target_list: Target[],
    artefactLinkString: "scorer" | "judge"
}

export function ArtefactTableArrayComponent({ phase_id, judges, head_judge, heat_number, target_list, artefactLinkString }: ArtefactTableArrayComponentProps) {

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
    const target_artefacts = transposeJudgeTargetArtefacts(target_list, htjaData);

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
                                <Link to={`${artefactLinkString}/${judgeId}`}>
                                    {judgeData.first_name}
                                    <br/>
                                    {judgeData.last_name}
                                </Link>
                            </th>
                        );
                    })}
                </tr>
                {target_artefacts && target_artefacts.map((htja_array, index) => {
                    return (
                        <> {htja_array.artefacts &&

                            <tr key={`${htja_array.artefacts[0].heat_target_judge.heat_number}-${htja_array.artefacts[0].heat_target_judge.target}`}
                                className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
                                <ArtefactRow htja_array={htja_array} />
                            </tr>
                        }
                        </>
                    );
                })}
            </tbody>
        </table>
    );
}

type ArtefactListComponentProps = {
    id_phase: PhaseId,
    heat_list: HeatsArray,
    judgePanel: Panel,
    artefactLinkString: "scorer" | "judge"
}

export function ArtefactListComponent({ id_phase, heat_list, judgePanel, artefactLinkString }: ArtefactListComponentProps) {

    const [isHeatView, setHeatView] = useState(false);

    if (heat_list.heat_type !== judgePanel.panel_type) return <div>Error Panel and Heats do not match</div>

    const targets = heat_list.heat_type === "single" ? {
        followers: heat_list.heats.flatMap(v => (v.followers)),
        leaders: heat_list.heats.flatMap(v => (v.leaders)),
    } : (heat_list.heat_type === "couple" ? {
        couples: heat_list.heats.flatMap(v => (v.couples))
    } : {});

    return (
        <>
            <button type='button' onClick={() => setHeatView(!isHeatView)}>Change heat view</button>
            {judgePanel.panel_type === "single" && !isHeatView && heat_list && heat_list.heats &&
                <>
                    <h1>Followers</h1>
                    <ArtefactTableArrayComponent
                        phase_id={id_phase}
                        judges={judgePanel.followers}
                        head_judge={judgePanel.head}
                        heat_number={undefined}
                        target_list={targets.followers ?? []}
                        artefactLinkString={artefactLinkString}
                    />
                    <h1>Leaders</h1>
                    <ArtefactTableArrayComponent
                        phase_id={id_phase}
                        judges={judgePanel.leaders}
                        head_judge={judgePanel.head}
                        heat_number={undefined}
                        target_list={targets.leaders ?? []}
                        artefactLinkString={artefactLinkString}
                    />
                </>
            }
            {judgePanel.panel_type === "single" && heat_list.heat_type === "single"
                && isHeatView && heat_list && heat_list.heats && heat_list.heats.map((v, heat_minus_one) => (
                    <>
                        <h1>Heat {heat_minus_one + 1} / {heat_list.heats.length}</h1>
                        <h2>Followers</h2>
                        <ArtefactTableArrayComponent
                            phase_id={id_phase}
                            judges={judgePanel.followers}
                            head_judge={judgePanel.head}
                            heat_number={heat_minus_one}
                            target_list={v.followers}
                            artefactLinkString={artefactLinkString}
                        />
                        <h2>Leaders</h2>
                        <ArtefactTableArrayComponent
                            phase_id={id_phase}
                            judges={judgePanel.leaders}
                            head_judge={judgePanel.head}
                            heat_number={heat_minus_one}
                            target_list={v.leaders}
                            artefactLinkString={artefactLinkString}
                        />
                    </>
                ))}
            {judgePanel.panel_type === "couple" && heat_list.heat_type === "couple"
                && !isHeatView && heat_list && heat_list.heats &&
                <>
                    <h1>Couples</h1>
                    <ArtefactTableArrayComponent
                        phase_id={id_phase}
                        judges={judgePanel.couples}
                        head_judge={judgePanel.head}
                        heat_number={undefined}
                        target_list={targets.couples ?? []}
                        artefactLinkString={artefactLinkString}
                    />
                </>
            }
            {judgePanel.panel_type === "couple" && heat_list.heat_type === "couple"
                && isHeatView && heat_list && heat_list.heats && heat_list.heats.map((v, heat_minus_one) => (
                    <>
                        <h1>Heat {heat_minus_one + 1} / {heat_list.heats.length}</h1>
                        <h2>Couples</h2>
                        <ArtefactTableArrayComponent
                            phase_id={id_phase}
                            judges={judgePanel.couples}
                            head_judge={judgePanel.head}
                            heat_number={heat_minus_one}
                            target_list={v.couples}
                            artefactLinkString={artefactLinkString}
                        />
                    </>
                ))}
        </>
    );
}
