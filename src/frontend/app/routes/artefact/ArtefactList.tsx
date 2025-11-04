import React, { useState } from 'react';

import type {
    CompetitionId, DancerId, PhaseId,
} from "@hookgen/model";
import { useParams } from "react-router";
import { useGetApiPhaseId } from "@hookgen/phase/phase";
import { useGetApiPhaseIdHeats, } from "~/hookgen/heat/heat";
import { useGetApiCompIdBibs } from '@hookgen/bib/bib';
import { useGetApiPhaseIdJudges } from '@hookgen/judge/judge';
import { ArtefactListComponent } from '@routes/artefact/ArtefactComponents';



export default function ArtefactList() {

    let { id_phase } = useParams();
    let id_phase_number = Number(id_phase) as PhaseId;
    const { data: phaseData, isLoading } = useGetApiPhaseId(id_phase_number);

    const { data: heat_list, isSuccess: isSuccessHeats } = useGetApiPhaseIdHeats(id_phase_number);

    const { data: dataBibs, isSuccess: isSuccessBibs } = useGetApiCompIdBibs(phaseData?.competition as CompetitionId);

    const { data: judgePanel, isSuccess: isSuccessJudges } = useGetApiPhaseIdJudges(id_phase_number);

    if (isLoading) return <div>Chargement...</div>;
    if (!phaseData) return null;
    if (!isSuccessBibs) return <div>Chargement des bibs...</div>;
    if (!isSuccessHeats) return <div>Chargement des heats...</div>;
    if (!isSuccessJudges) return <div>Chargement des juges...</div>;

    return (
        <>
            <ArtefactListComponent id_phase={id_phase_number} heat_list={heat_list} dataBibs={dataBibs} judgePanel={judgePanel} />
        </>
    );
}
