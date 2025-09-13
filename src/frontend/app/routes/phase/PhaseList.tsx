import type { Route } from "./+types/PhaseList";
import React from 'react';
import { Link } from "react-router";

import { getApiCompId, useGetApiCompId } from '@hookgen/competition/competition';
import type { ArtefactDescription, Competition, CompetitionId, EventId } from "@hookgen/model";
import { getApiCompIdPhases, useGetApiCompIdPhases, useGetApiPhaseId } from "@hookgen/phase/phase";
import ArtefactDescriptionComponent from "@routes/phase/ArtefactDescription";
import { getApiEventId, getApiEventIdComps } from "@hookgen/event/event";


export async function loader({ params }: Route.LoaderArgs) {

    let id_event = Number(params.id_event) as EventId;
    const event_data = await getApiEventId(id_event);
    const competition_list = await getApiEventIdComps(id_event);
    const id_competition = Number(params.id_competition) as CompetitionId;
    const competition_data = await getApiCompId(id_competition);
    const phase_list = await getApiCompIdPhases(id_competition);
    return {
        id_event,
        id_competition,
        event_data,
        competition_list,
        competition_data,
        phase_list,
    };
}


function PhaseDetails({ id, competition_id, competition_data, index }: { id: CompetitionId, competition_id: CompetitionId, competition_data: Competition, index: number }) {
    const { data: phase, isLoading } = useGetApiPhaseId(id);

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
                <Link to={`/events/${competition_data.event}/competitions/${competition_id}/phases/${id}`}>
                    {phase?.round} {competition_data?.name}
                </Link>
            </td>
            <td>
                <Link to={`/competitions/${phase?.competition}`}>
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

export function PhaseList({ id_competition, competition_data }: { id_competition: CompetitionId, competition_data: Competition }) {

    const { data, isLoading, isError, error } = useGetApiCompIdPhases(id_competition);

    console.log("PhaseList", id_competition, data?.phases);

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

                    {data?.phases && data?.phases.map((phaseId, index) => (
                        <PhaseDetails key={phaseId} id={phaseId} competition_id={id_competition} competition_data={competition_data} index={index} />
                    ))}
                </tbody>
            </table>
        </>
    );
}


export default function PhaseListRoute({ loaderData }: Route.ComponentProps) {

    return (<PhaseList
        id_competition={loaderData.id_competition}
        competition_data={loaderData.competition_data} />);

}