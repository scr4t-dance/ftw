import "../styles/ContentStyle.css";

import React from 'react';
import { useGetApiCompId } from '../hookgen/competition/competition';

import { ArtefactDescription, CompetitionId } from "hookgen/model";
import { Link } from "react-router";
import { useGetApiCompIdPhases, useGetApiPhaseId } from "hookgen/phase/phase";
import ArtefactDescriptionComponent from "./ArtefactDescription";

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
                        <th>Phase</th>
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

    const phase = data?.data;
    const { data: dataComp } = useGetApiCompId(phase?.competition as CompetitionId);

    if (isLoading) return (
        <tr>
            <td>
                Chargement...
            </td>
        </tr>
    );
    if (!data) return null;

    const competition = dataComp?.data;

    return (
        <tr key={id}
            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>

            <td>
                <Link to={`/${phaseListlink}${id}`}>
                    {phase?.round} {competition?.name}
                </Link>
            </td>
            <td>
                <Link to={`/competitions/${phase?.competition}`}>
                    {competition?.name}
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

export default PhaseList;