import React from 'react';

import type { BibList, CompetitionId, CouplesHeat, DancerId, PhaseId, SinglesHeat, Target } from "@hookgen/model";
import { useParams } from "react-router";
import { useGetApiPhaseId } from "@hookgen/phase/phase";
import { useGetApiPhaseIdHeats } from "@hookgen/heat/heat";
import { BareBibListComponent } from '@routes/bib/BibComponents';
import { useGetApiCompIdBibs } from '@hookgen/bib/bib';
import { InitHeatsWithBibForm, RandomizeHeatsForm } from '@routes/heat/InitHeatsForm';

const iter_target_dancers = (t: Target) => t.target_type === "single"
    ? [t.target]
    : [t.follower, t.leader];

function SingleHeatTable({ heat, dataBibs }: { heat: SinglesHeat, dataBibs: BibList }) {


    const followers: DancerId[] = heat.followers.flatMap(u => iter_target_dancers(u));
    const leaders: DancerId[] = heat.leaders.flatMap(u => iter_target_dancers(u));
    const get_bibs = (dancer_list: DancerId[]) => dataBibs?.bibs.filter(b => iter_target_dancers(b.target).map(dancer => dancer_list?.includes(dancer)).includes(true));

    return (
        <>
            <p>Followers</p>
            <BareBibListComponent bib_list={get_bibs(followers)} ></BareBibListComponent>
            <p>Leaders</p>
            <BareBibListComponent bib_list={get_bibs(leaders)} ></BareBibListComponent>
        </>);
}


function CoupleHeatTable({ heat, dataBibs }: { heat: CouplesHeat, dataBibs: BibList }) {


    const get_bibs = (dancer_list: DancerId[]) => dataBibs?.bibs.filter(b => iter_target_dancers(b.target).map(dancer => dancer_list?.includes(dancer)).includes(true));

    return (
        <>
            <p>Couples</p>
            <BareBibListComponent bib_list={get_bibs(heat.couples.flatMap(u => iter_target_dancers(u)))} ></BareBibListComponent>
        </>);
}

export default function HeatsList() {

    let { id_phase } = useParams();
    let id_phase_number = Number(id_phase) as PhaseId;
    const { data: phaseData, isLoading } = useGetApiPhaseId(id_phase_number);

    const { data: heats, isSuccess: isSuccessHeats } = useGetApiPhaseIdHeats(id_phase_number);

    const { data: dataBibs, isSuccess: isSuccessBibs } = useGetApiCompIdBibs(phaseData?.competition as CompetitionId);

    if (isLoading) return <div>Chargement...</div>;
    if (!phaseData) return null;
    if (!isSuccessBibs) return <div>Chargement des bibs...</div>;
    if (!isSuccessHeats) return <div>Chargement des heats...</div>;

    console.log("heat_type ", heats.heat_type);

    return (
        <>
            <p>
                <InitHeatsWithBibForm id_phase={id_phase_number} />
                <RandomizeHeatsForm id_phase={id_phase_number} />
            </p>

            {heats?.heats && heats?.heats.map((heat, index) => (
                <>
                    <h1>Heat {index}</h1>
                    {heats.heat_type === "couple" &&
                        <CoupleHeatTable heat={heat as CouplesHeat}
                            dataBibs={dataBibs}
                        />
                    }
                    {heats.heat_type === "single" &&
                        <SingleHeatTable heat={heat as SinglesHeat}
                            dataBibs={dataBibs}
                        />
                    }
                </>
            ))}

        </>
    );
}

export const handle = {
    breadcrumb: () => "Heats"
};
