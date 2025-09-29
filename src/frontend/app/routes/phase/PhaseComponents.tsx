import { Link, useLocation } from "react-router";
import type { ArtefactDescription, Competition, CompetitionId, Phase, PhaseIdList } from "@hookgen/model";
import { useGetApiCompIdPhases, useGetApiPhaseId } from "@hookgen/phase/phase";
import ArtefactDescriptionComponent from "@routes/phase/ArtefactDescription";



export function PhaseDetails({ id, competition_id, competition_data, index }: { id: CompetitionId, competition_id: CompetitionId, competition_data: Competition, index: number }) {
    const { data: phase, isLoading } = useGetApiPhaseId(id);

    const location = useLocation();
    const url = location.pathname.includes("phase") ? "" : "phases/";

    if (isLoading) return (
        <tr>
            <td>
                Chargement...
            </td>
        </tr>
    );
    if (!phase) return null;


    return (
        <tr key={id}
            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>

            <td>
                <Link to={`${url}${id}`}>
                    {phase?.round} {competition_data?.name}
                </Link>
            </td>
            <td>
                <Link to={`${url}..`}>
                    {competition_data?.name}
                </Link>
            </td>
            <td>
                {phase?.round}
            </td>
            <td>
                <ArtefactDescriptionComponent
                    artefact_description={phase?.judge_artefact_descr as ArtefactDescription}
                />
            </td>
            <td>
                <ArtefactDescriptionComponent
                    artefact_description={phase?.head_judge_artefact_descr as ArtefactDescription}
                />
            </td>
        </tr>

    );
}

export function PhaseListComponent({ id_competition, competition_data, phase_list }: { id_competition: CompetitionId, competition_data: Competition, phase_list: PhaseIdList }) {

    return (
        <>
            <h1>Liste Phases</h1>
            <table>
                <tbody>
                    <tr>
                        <th>Phase</th>
                        <th>Compétition</th>
                        <th>Round</th>
                        <th>Artefact Juges</th>
                        <th>Artefact Head Juge</th>
                    </tr>

                    {phase_list?.phases && phase_list?.phases.map((phaseId, index) => (
                        <PhaseDetails key={phaseId} id={phaseId} competition_id={id_competition} competition_data={competition_data} index={index} />
                    ))}
                </tbody>
            </table>
        </>
    );
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
