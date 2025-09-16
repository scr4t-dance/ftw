import React from 'react';

import type { BibList, CompetitionId, CouplesHeat, CouplesHeatsArray, DancerId, HeatsArray, PhaseId, SinglesHeat, SinglesHeatsArray, Target } from "@hookgen/model";
import { data, Link, useParams } from "react-router";
import { useGetApiPhaseId } from "@hookgen/phase/phase";
import { getGetApiPhaseIdCouplesHeatsQueryKey, getGetApiPhaseIdHeatsQueryKey, getGetApiPhaseIdSinglesHeatsQueryKey, useGetApiPhaseIdHeats, useGetApiPhaseIdSinglesHeats, usePutApiPhaseIdInitHeats, usePutApiPhaseIdPromote } from "~/hookgen/heat/heat";
import { useQueries, useQueryClient } from "@tanstack/react-query";
import { BareBibListComponent } from '../bib/BibList';
import { useGetApiCompIdBibs } from '~/hookgen/bib/bib';

const iter_target_dancers = (t: Target) => t.target_type === "single"
    ? [t.target]
    : [t.follower, t.leader];

function SingleHeatTable({ heat, dataBibs }: { heat: SinglesHeat, dataBibs: BibList }) {


    const followers : DancerId[] = heat.followers.flatMap(u => iter_target_dancers(u));
    const leaders : DancerId[] = heat.leaders.flatMap(u => iter_target_dancers(u));
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

    const queryClient = useQueryClient();

    const { mutate } = usePutApiPhaseIdInitHeats({
        mutation: {
            onSuccess: () => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdCouplesHeatsQueryKey(id_phase_number),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdSinglesHeatsQueryKey(id_phase_number),
                });
            },
            onError: (err) => {
                console.error('Error creating phase:', err);
            }
        }
    });

    const { mutate: promotePhase } = usePutApiPhaseIdPromote({
        mutation: {
            onSuccess: (nextPhase) => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdCouplesHeatsQueryKey(nextPhase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdSinglesHeatsQueryKey(nextPhase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdHeatsQueryKey(nextPhase),
                });
            },
            onError: (err) => {
                console.error('Error creating phase:', err);
            }
        }
    });

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
                <button type="button" onClick={() => {
                    console.log("init heats")
                    mutate({ id: id_phase_number, data: 0 })
                }}>
                    Init heats
                </button>

                <button type="button" onClick={() => {
                    console.log("init heats")
                    promotePhase({ id: id_phase_number, data: 0 })
                }}>
                    Promote
                </button>
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
