import type { Route } from './+types/PhasePage';
import React from 'react';

import type { Competition, CompetitionId, EventId, Phase, PhaseId } from "@hookgen/model";
import { getApiEventId, getApiEventIdComps } from '@hookgen/event/event';
import { getApiCompId } from '@hookgen/competition/competition';
import { getApiPhaseId } from '@hookgen/phase/phase';


export async function loader({ params }: Route.LoaderArgs) {

    let id_event = Number(params.id_event) as EventId;
    const event_data = await getApiEventId(id_event);
    const competition_list = await getApiEventIdComps(id_event);
    const id_competition = Number(params.id_competition) as CompetitionId;
    const competition_data = await getApiCompId(id_competition);
    const id_phase = Number(params.id_phase) as PhaseId;
    const phase_data = await getApiPhaseId(id_phase);
    return {
        id_event,
        id_competition,
        event_data,
        competition_list,
        competition_data,
        id_phase,
        phase_data,
    };
}

export function PhasePage({ phase_data, competition_data }: { phase_data: Phase, competition_data: Competition }) {
    const ranking_algorithm_algorithm = phase_data.ranking_algorithm.algorithm;
    const judgesArtefactDescription = phase_data.judge_artefact_descr;
    const headJudgeArtefactDescription = phase_data.head_judge_artefact_descr;

    const j_fields = (ranking_algorithm_algorithm === "Yan_weighted") ? phase_data.ranking_algorithm.weights : undefined;
    const hj_fields = (ranking_algorithm_algorithm === "Yan_weighted") ? phase_data.ranking_algorithm.head_weights : undefined;

    return (
        <>
            <h2>Détails</h2>
            <p>Catégorie {competition_data.category}</p>
            <p>Round {phase_data.round}</p>
            {ranking_algorithm_algorithm === 'Yan_weighted' &&
                <>
                    <h3>Notation juges</h3>
                    <table>
                        <thead>
                            <tr>
                                <th>Critère</th>
                                <th>Yes</th>
                                <th>Alt</th>
                                <th>No</th>
                            </tr>
                        </thead>
                        <tbody>
                            {judgesArtefactDescription.artefact === "yan" &&
                                j_fields && j_fields.map((weights, index) => (
                                    <tr>
                                        <td>{judgesArtefactDescription.artefact_data && judgesArtefactDescription.artefact_data[index]}</td>
                                        <td>{weights.yes}</td>
                                        <td>{weights.alt}</td>
                                        <td>{weights.no}</td>
                                    </tr>
                                ))}
                        </tbody>
                    </table>
                    <h3>Notations head judge</h3>
                    <table>
                        <thead>
                            <tr>
                                <th>Critère</th>
                                <th>Yes</th>
                                <th>Alt</th>
                                <th>No</th>
                            </tr>
                        </thead>
                        <tbody>
                            {headJudgeArtefactDescription.artefact === "yan" && hj_fields && hj_fields.map((weights, index) => (
                                <tr>
                                    <td>{headJudgeArtefactDescription.artefact_data && headJudgeArtefactDescription.artefact_data[index]}</td>
                                    <td>{weights.yes}</td>
                                    <td>{weights.alt}</td>
                                    <td>{weights.no}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </>
            }
            {ranking_algorithm_algorithm === 'ranking' &&
                <>
                    <div>
                        <label>Algorithm for Ranking:</label>
                        RPSS
                    </div>
                </>}

        </>
    );

}

export default function PhasePageRoute({
    loaderData
}: Route.ComponentProps) {

    return (<PhasePage phase_data={loaderData.phase_data} competition_data={loaderData.competition_data} />);
}
