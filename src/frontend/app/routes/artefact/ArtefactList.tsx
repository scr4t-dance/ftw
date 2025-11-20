import React, { useState } from 'react';
import type { Route } from './+types/ArtefactList';

import { useSearchParams } from "react-router";

import type {
    CompetitionId, PhaseId,
} from "@hookgen/model";
import { useGetApiPhaseId } from "@hookgen/phase/phase";
import { useGetApiPhaseIdHeats, } from "@hookgen/heat/heat";
import { useGetApiCompIdBibs } from '@hookgen/bib/bib';
import { useGetApiPhaseIdJudges } from '@hookgen/judge/judge';
import { ArtefactListComponent } from '@routes/artefact/ArtefactComponents';



export default function ArtefactList({ params }: Route.ComponentProps) {

    let [searchParams] = useSearchParams({ for: "judge" })

    let id_phase = Number(params.id_phase) as PhaseId;
    const { data: phaseData, isLoading } = useGetApiPhaseId(id_phase);

    const { data: heat_list, isSuccess: isSuccessHeats } = useGetApiPhaseIdHeats(id_phase);

    const { data: dataBibs, isSuccess: isSuccessBibs } = useGetApiCompIdBibs(phaseData?.competition as CompetitionId);

    const { data: judgePanel, isSuccess: isSuccessJudges } = useGetApiPhaseIdJudges(id_phase);

    const artefactLinkString = searchParams.get("for");
    if (artefactLinkString !== "scorer" && artefactLinkString !== "judge") return (<div>
        Il est attendu d'avoir "?for=judge" ou "?for=scorer" en fin d'URL.
    </div>);
    if (isLoading) return <div>Chargement...</div>;
    if (!phaseData) return null;
    if (!isSuccessBibs) return <div>Chargement des bibs...</div>;
    if (!isSuccessHeats) return <div>Chargement des heats...</div>;
    if (!isSuccessJudges) return <div>Chargement des juges...</div>;

    return (
        <>
            <ArtefactListComponent id_phase={id_phase} heat_list={heat_list} dataBibs={dataBibs} judgePanel={judgePanel} artefactLinkString={artefactLinkString} />
        </>
    );
}
