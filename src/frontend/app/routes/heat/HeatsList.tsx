import React from 'react';

import type { CompetitionId, DancerId, PhaseId, Target } from "@hookgen/model";
import { Link, useParams } from "react-router";
import { useGetApiPhaseId } from "@hookgen/phase/phase";
import { getGetApiPhaseIdCouplesHeatsQueryKey, getGetApiPhaseIdSinglesHeatsQueryKey, useGetApiPhaseIdSinglesHeats, usePutApiPhaseIdInitHeats, usePutApiPhaseIdPromote } from "~/hookgen/heat/heat";
import { useQueries, useQueryClient } from "@tanstack/react-query";
import { BareBibListComponent } from '../bib/BibList';
import { useGetApiCompIdBibs } from '~/hookgen/bib/bib';


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

    const { mutate : promotePhase } = usePutApiPhaseIdPromote({
        mutation: {
            onSuccess: (nextPhase) => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdCouplesHeatsQueryKey(nextPhase),
                });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdSinglesHeatsQueryKey(nextPhase),
                });
            },
            onError: (err) => {
                console.error('Error creating phase:', err);
            }
        }
    });

    const { data: heat_list, isSuccess: isSuccessHeats } = useGetApiPhaseIdSinglesHeats(id_phase_number);

    const iter_target_dancers = (t: Target) => t.target_type === "single"
        ? [t.target]
        : [t.follower, t.leader];

    const { data: dataBibs, isSuccess: isSuccessBibs } = useGetApiCompIdBibs(phaseData?.competition as CompetitionId);

    if (isLoading) return <div>Chargement...</div>;
    if (!phaseData) return null;
    if (!isSuccessBibs) return <div>Chargement des bibs...</div>;
    if (!isSuccessHeats) return <div>Chargement des heats...</div>;

    const followers = heat_list.heats.flatMap(v => (v.followers.flatMap(u => iter_target_dancers(u))));
    const leaders = heat_list.heats.flatMap(v => (v.leaders.flatMap(u => u.target)));
    const get_bibs = (dancer_list: DancerId[]) => dataBibs?.bibs.filter(b => iter_target_dancers(b.target).map(dancer => dancer_list?.includes(dancer)).includes(true));

    return (
        <>
            <h1>Phase {phaseData?.round}</h1>


            <p>
                <Link to={`/competitions/${phaseData?.competition}`}>
                    Competition
                </Link>
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

            {heat_list && heat_list.heats && heat_list.heats.map((v, heat) => (
                <>
                    <h1>Heat {heat}</h1>
                    <p>Followers</p>
                    <BareBibListComponent bib_list={get_bibs(v.followers.flatMap(u => iter_target_dancers(u)))} ></BareBibListComponent>
                    <p>Followers</p>
                    <BareBibListComponent bib_list={get_bibs(v.leaders.flatMap(u => iter_target_dancers(u)))} ></BareBibListComponent>
                </>
            ))}

        </>
    );
}
