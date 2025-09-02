import React from 'react';

import type { PhaseId } from "@hookgen/model";
import { useParams } from "react-router";
import { EditPhaseForm } from "./EditPhaseForm";

function PhasePage() {

    let { id_phase } = useParams();
    let id_phase_number = Number(id_phase) as PhaseId;

    return (
        <>
            <EditPhaseForm phase_id={id_phase_number} />
        </>
    );
}

export default PhasePage;