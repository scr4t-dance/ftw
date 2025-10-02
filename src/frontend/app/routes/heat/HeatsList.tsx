import React from 'react';

import type { CompetitionId, PhaseId, } from "@hookgen/model";
import { useParams } from "react-router";
import { useGetApiPhaseId } from "@hookgen/phase/phase";
import {
    useGetApiPhaseIdHeats,
} from "@hookgen/heat/heat";
import { useGetApiCompIdBibs } from '@hookgen/bib/bib';
import { HeatsListComponent } from './HeatComponents';


export default function HeatsList() {

    let { id_phase:id_phase_string } = useParams();
    let id_phase = Number(id_phase_string) as PhaseId;
    const { data: phaseData, isLoading } = useGetApiPhaseId(id_phase);

    const { data: heats, isSuccess: isSuccessHeats } = useGetApiPhaseIdHeats(id_phase);

    const { data: dataBibs, isSuccess: isSuccessBibs } = useGetApiCompIdBibs(phaseData?.competition as CompetitionId);

    if (isLoading) return <div>Chargement...</div>;
    if (!phaseData) return null;
    if (!isSuccessBibs) return <div>Chargement des bibs...</div>;
    if (!isSuccessHeats) return <div>Chargement des heats...</div>;

    return <HeatsListComponent id_phase={id_phase} heats={heats} dataBibs={dataBibs} />

}

export const handle = {
    breadcrumb: () => "Heats"
};
