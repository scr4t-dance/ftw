import "../styles/ContentStyle.css";

import React from 'react';
import { useGetApiCompId } from '../hookgen/competition/competition';
import { useGetApiEventIdComps } from "hookgen/event/event";

import { CompetitionId } from "hookgen/model";
import { Link } from "react-router";
import { useGetApiCompIdPhases, useGetApiPhaseId } from "hookgen/phase/phase";

const phaseListlink = "phases/"

function PhaseList({ id_competition }: { id_competition: CompetitionId }) {

    const { data, isLoading, isError, error } = useGetApiCompIdPhases(id_competition);

    console.log(data?.data.phases)

    if (isLoading) return <div>Chargement des phases...</div>;
    if (isError) return <div>Erreur: {(error as any).message}</div>;

    return (
        <>
            <h1>Liste Phases</h1>
            <table>
                <tbody>
                    <tr>
                        <th>Nom de la Phase</th>
                        <th>Compétition</th>
                        <th>Round</th>
                        <th>Artefact Juges</th>
                        <th>Artefact Head Juge</th>
                    </tr>

                    {data?.data.phases && data?.data.phases.map((phaseId, index) => (
                        <PhaseDetails key={phaseId} id={phaseId} index={index} />
                    ))}
                </tbody>
            </table>
        </>
    );
}


function PhaseDetails({ id, index }: { id: CompetitionId, index: number }) {
    const { data, isLoading } = useGetApiPhaseId(id);

    if (isLoading) return <div>Chargement...</div>;
    if (!data) return null;

    const phase = data.data;

    return (
        <tr key={id}
            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
            <Link to={`/${phaseListlink}${id}`}>
                <td>{phase.competition}</td>
                <td>{phase.round}</td>
            </Link>
            <td>{phase.judge_artefact_description && phase.judge_artefact_description.toString()}</td>
            <td>{phase.head_judge_artefact_description && phase.head_judge_artefact_description.toString()}</td>
        </tr>

    );
}

export default PhaseList;