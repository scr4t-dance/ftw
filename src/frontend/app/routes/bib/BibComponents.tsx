
import React, { useEffect, useState } from 'react';
import { Link } from "react-router";

import { useGetApiDancerId } from '@hookgen/dancer/dancer';
import {
    type Bib, type BibList, type Competition, type CompetitionId, type CompetitionIdList, type CoupleTarget, type DancerId,
    type EventId, RoleItem,
    type SingleTarget, type Target, type OldBibNewBib,
} from "@hookgen/model";

import {
    useGetApiCompIdBibs, useDeleteApiCompIdBib,
    getGetApiCompIdBibsQueryKey, usePatchApiCompIdBib,
    getGetApiCompIdBibsQueryOptions,
} from "@hookgen/bib/bib";
import { useForm, type UseFormReturn } from "react-hook-form";
import { Field } from "@routes/index/field";
import { useQueries, useQueryClient } from '@tanstack/react-query';
import { useGetApiEventIdComps } from '@hookgen/event/event';
import { getGetApiCompIdQueryOptions } from '@hookgen/competition/competition';
import { NewTargetBibFormComponent } from '@routes/bib/NewBibFormComponent';

const dancerLink = "dancers/"

function to_single_targets(target: Target) {

    return target.target_type === "couple" ?
        [
            { target_type: "single", target: target.leader, role: ["Leader"] } satisfies Target,
            { target_type: "single", target: target.follower, role: ["Follower"] } satisfies Target,
        ] : [target]
        ;
}

export function get_bibs(dataBibs: BibList, target_list: Target[]): Bib[][] {
    const bibs_list = target_list.map(
        (t) => dataBibs.bibs.find(b => JSON.stringify(b.target) === JSON.stringify(t))
    );

    const single_bibs = dataBibs.bibs.flatMap(b => to_single_targets(b.target).map(t => ({ bib: b.bib, competition: b.competition, target: t } as Bib)));

    const imputed_bib_list = target_list.map((tt, index) => bibs_list[index] ? [bibs_list[index]] :
        tt.target_type === "couple" ? (
            to_single_targets(tt).map(t =>
                dataBibs.bibs.find(b => JSON.stringify(b.target) === JSON.stringify(t)
                )
            )
        ) : (
            [single_bibs.find(b => JSON.stringify(b.target) === JSON.stringify(tt))]
        )
    );

    return imputed_bib_list.map(b_list => (b_list.filter(b => !!b)));
}

function convert_target(target: Target | undefined) {

    if (target === undefined) {
        return []
    }

    if (target.target_type === "single") {
        const single_target = [target as SingleTarget];

        return single_target;
    } else {
        const couple_target = target as CoupleTarget;
        const single_target: SingleTarget[] = [
            { target_type: "single", target: couple_target.leader, role: [RoleItem.Leader] },
            { target_type: "single", target: couple_target.follower, role: [RoleItem.Follower] },

        ];

        return single_target;
    }

}

function convert_bib_to_single_target(bib: Bib): Bib[] {

    const single_target_array = convert_target(bib?.target);
    return single_target_array.map((t, index) => ({ ...bib, target: t }));

}

export function dancerArrayFromTarget(t: Target): DancerId[] {
    return t.target_type === "single"
        ? [t.target]
        : [t.follower, t.leader]
}


export function DancerCell({ id_dancer, link }: { id_dancer: DancerId, link?: boolean }) {

    const { data: dancer } = useGetApiDancerId(id_dancer);

    if (!dancer) return "Loading dancer..."

    if (link ?? true) return (<>{dancer.last_name} {dancer.first_name}</>);

    return (
        <>
            <Link to={`/${dancerLink}${id_dancer}`}>
                {dancer.last_name} {dancer.first_name}
            </Link>
        </>
    )
}

type BibRowReadOnlyProps = {
    bib_object: Bib;
    onEdit: () => void;
    onDelete: () => void
};

export function BibRowReadOnly({ bib_object, onEdit, onDelete }: BibRowReadOnlyProps) {

    const dancer_list = dancerArrayFromTarget(bib_object.target);
    return (
        <>
            <td>
                {bib_object.target.target_type}
            </td>
            <td>{bib_object.bib}</td>

            <td>{bib_object.target.target_type === "single" ?
                bib_object.target.role :
                <> {RoleItem.Follower}
                    <br /> {RoleItem.Leader}
                </>
            }</td>
            <td>
                {dancer_list && dancer_list.map((i) => (
                    <p key={i}>
                        <DancerCell id_dancer={i} link={false} />
                    </p>
                ))
                }
            </td>
            <td className='no-print'>
                <button type="button" onClick={() => onEdit()}>
                    Edition
                </button>
                <button type="button" onClick={() => onDelete()}>
                    Delete
                </button>
            </td>
        </>

    );
}

type BibRowEditableProps = {
    formObject: UseFormReturn<OldBibNewBib, any, OldBibNewBib>;
    onUpdate: () => void;
    onCancel: () => void;
};

function BibRowEditable({ formObject, onUpdate, onCancel }: BibRowEditableProps) {
    const {
        register,
        formState: { errors },
        watch
    } = formObject;

    const targetType = watch("new_bib.target.target_type");

    return (
        <>
            <td>
                {targetType}
            </td>

            <td>
                <Field label="" error={errors?.new_bib?.bib?.message}>
                    <input type="number" {...register("new_bib.bib", {
                        valueAsNumber: true,
                        required: true,
                        min: {
                            value: 0,
                            message: "Le numéro de dossard doit être un entier positif.",
                        },
                    })}
                    />
                </Field>
            </td>

            {targetType === "single" && (
                <>
                    <td><DancerCell id_dancer={formObject.getValues("new_bib.target.target")} /></td>
                    <td>{formObject.getValues("new_bib.target.role")?.join(", ")}</td>
                </>
            )}

            {targetType === "couple" && (
                <>
                    <td><DancerCell id_dancer={formObject.getValues("new_bib.target.follower")} /></td>
                    <td><DancerCell id_dancer={formObject.getValues("new_bib.target.leader")} /></td>
                </>
            )}
            <td>
                <button type="button" onClick={() => onUpdate()}>Màj</button>
                <button type="button" onClick={() => onCancel()} >Annuler</button>
            </td>
        </>
    );
}

function EditableBibDetails({ bib_object }: { bib_object: Bib }) {

    const queryClient = useQueryClient();

    const [isEditing, setIsEditing] = useState(false);

    const formObject = useForm<OldBibNewBib>({
        defaultValues: {old_bib: bib_object, new_bib: bib_object}
    });

    const {
        handleSubmit,
        reset,
        setError,
    } = formObject;

    const { mutate: updateBib } = usePatchApiCompIdBib({
        mutation: {
            onSuccess: (_, variables) => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiCompIdBibsQueryKey(bib_object.competition),
                });
                reset(variables.data);
                setIsEditing(false);
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
                setError("root.serverError", { message: 'Erreur lors de l’ajout de la compétition.' });
            }
        }
    });

    const { mutate: deleteBib } = useDeleteApiCompIdBib({
        mutation: {
            onSuccess: () => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiCompIdBibsQueryKey(bib_object.competition),
                });
            },
        }
    });

    const handleUpdate = handleSubmit((data) => {
        updateBib({ id: bib_object.competition, data });
    });

    const handleCancel = () => {
        reset();
        setIsEditing(false);
    };

    return (
        <>
            {
                isEditing ? (
                    <BibRowEditable
                        formObject={formObject}
                        onUpdate={handleUpdate}
                        onCancel={handleCancel}
                    />
                ) : (
                    <BibRowReadOnly
                        bib_object={bib_object}
                        onEdit={() => setIsEditing(true)}
                        onDelete={() => deleteBib({
                            id: bib_object.competition, data: bib_object
                        })
                        }
                    />
                )
            }
        </>
    );
}

export function BareBibListComponent({ bib_list }: { bib_list: Array<Bib> }) {

    return (
        <>
            <table>
                <tbody>
                    <tr>
                        <th>Type target</th>
                        <th>Bib</th>
                        <th>Rôle</th>
                        <th>Target</th>
                        <th className='no-print'>Action</th>
                    </tr>

                    {bib_list.map((bibObject, index) => (
                        <tr key={`${bibObject.competition}-${bibObject.bib}`}
                            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
                            <EditableBibDetails bib_object={bibObject} />
                        </tr >
                    ))}
                </tbody>
            </table>
        </>
    );
}


export function PublicBibList({ bib_list }: { bib_list: Array<Bib> }) {

    return (
        <>
            <table>
                <tbody>
                    <tr>
                        <th>Type target</th>
                        <th>Bib</th>
                        <th>Rôle</th>
                        <th>Target</th>
                    </tr>

                    {bib_list.map((bib_object, index) => (
                        <tr key={`${bib_object.competition}-${bib_object.bib}`}
                            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
                            <td>
                                {bib_object.target.target_type}
                            </td>
                            <td>{bib_object.bib}</td>

                            <td>{bib_object.target.target_type === "single" ?
                                bib_object.target.role :
                                <> {RoleItem.Follower}
                                    <br /> {RoleItem.Leader}
                                </>
                            }</td>
                            <td>
                                {dancerArrayFromTarget(bib_object.target).map((i) => (
                                    <p key={i}>
                                        <DancerCell id_dancer={i} />
                                    </p>
                                ))
                                }
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </>
    );
}

export function BibListComponent({ id_competition }: { id_competition: CompetitionId }) {

    console.log("BibListComponent", id_competition);
    const { data, isLoading, error } = useGetApiCompIdBibs(id_competition);

    const bib_list = data as BibList;

    if (isLoading) return <div>Chargement des compétiteur-euses...</div>;
    if (error) return <div>Erreur: {(error as any).message}</div>;

    return (
        <>
            {bib_list &&
                <>
                    <BareBibListComponent bib_list={bib_list.bibs} />
                </>
            }
        </>
    );
}


export function PublicBibListComponent({ id_competition }: { id_competition: CompetitionId }) {

    console.log("BibListComponent", id_competition);
    const { data, isLoading, error } = useGetApiCompIdBibs(id_competition);

    const bib_list = data as BibList;

    if (isLoading) return <div>Chargement des compétiteur-euses...</div>;
    if (error) return <div>Erreur: {(error as any).message}</div>;

    return (
        <>
            {bib_list.bibs &&
                <>
                    <PublicBibList bib_list={bib_list.bibs} />
                </>
            }
        </>
    );
}
type BibListEventAdminProps = {
    competition_list: CompetitionIdList,
    competition_data_list: Competition[],
    bibs_list_array: BibList[]
}

export function BibListEventAdmin({ competition_list, competition_data_list, bibs_list_array }: BibListEventAdminProps) {

    const dancer_list = [...new Set(bibs_list_array.flatMap((bibs_list) => (
        bibs_list.bibs.flatMap((bib) => dancerArrayFromTarget(bib.target)))
    ))];

    const target_list_duplicates = dancer_list.map((id_dancer) => (
        bibs_list_array.flatMap((bib_list) => (
            bib_list.bibs.filter((bib) => dancerArrayFromTarget(bib.target).includes(id_dancer))
        ).map((bib) => bib.target))
    ));

    const target_list = target_list_duplicates.map((target_dups) =>
        [...new Set(target_dups.map((x) => JSON.stringify(x)))].map((x) => JSON.parse(x) as Target
        ));


    const bib_key = dancer_list.map((id_dancer) => (
        bibs_list_array.flatMap((bib_list) => (
            bib_list.bibs.filter((bib) => dancerArrayFromTarget(bib.target).includes(id_dancer))
        ).map((bib) => bib.target))
    ));

    return (
        <>
            <h1>Liste Compétiteur-ices</h1>
            <table>
                <tbody>
                    <tr>
                        <th>Target</th>
                        {competition_list.competitions.map((id_competition, index) => (
                            <th key={id_competition} colSpan={5}>
                                <Link to={`../competitions/${id_competition}`}>{competition_data_list[index].name}</Link>
                            </th>
                        ))}
                    </tr>
                    {dancer_list.map((id_dancer, d_index) => (
                        target_list[d_index].map((target, t_index) => {
                            const bibs = competition_list.competitions.map((_, index) =>
                                bibs_list_array[index].bibs.find((bib) => (
                                    JSON.stringify(bib.target) === JSON.stringify(target)
                                )));

                            const bib_key = [id_dancer, dancerArrayFromTarget(target).join("-")].concat(
                                bibs.filter(b => b).map(b => b as Bib).map(
                                    b => [String(b.competition), String(b.bib)].join("_")
                                )).join("|");

                            return (
                                <tr key={bib_key}>
                                    <td>
                                        <DancerCell id_dancer={id_dancer} />
                                    </td>

                                    {competition_list.competitions.map((id_competition, index) => {


                                        if (bibs[index] === undefined) {
                                            return (
                                                <td key={id_competition} colSpan={5}>
                                                    <NewTargetBibFormComponent id_competition={id_competition} bibs_list={bibs_list_array[index]} target={target} />
                                                </td>
                                            );
                                        }

                                        return <EditableBibDetails key={id_competition} bib_object={bibs[index]} />
                                    })}
                                </tr>
                            );
                        })
                    ))}
                    <tr>

                        <td>New</td>
                        {competition_list.competitions.map((id_competition) => (
                            <td key={id_competition} colSpan={5}>
                                <Link to={`../competitions/${id_competition}/bibs/new`}>Nouveau bib Compétition {id_competition}</Link>
                            </td>
                        ))}
                    </tr>
                </tbody>
            </table>
        </>
    );
}


export function BibListEventAdminComponent({ id_event }: { id_event: EventId }) {

    const { data: competition_list, isSuccess } = useGetApiEventIdComps(id_event);

    const competitionDetailsQueries = useQueries({
        queries: (competition_list ?? { competitions: [] }).competitions.map((competitionId) => ({
            ...getGetApiCompIdQueryOptions(competitionId),
            enabled: !!competition_list,
        })),
    });

    const competitionBibsQueries = useQueries({
        queries: (competition_list ?? { competitions: [] }).competitions.map((competitionId) => ({
            ...getGetApiCompIdBibsQueryOptions(competitionId),
            enabled: !!competition_list,
        })),
    });


    const isDetailsLoading = competitionDetailsQueries.some((query) => query.isLoading);
    const isDetailsError = competitionDetailsQueries.some((query) => query.isError);
    const isBibsLoading = competitionBibsQueries.some((query) => query.isLoading);
    const isBibsError = competitionBibsQueries.some((query) => query.isError);


    if (!isSuccess) return <div>Loading competition details...</div>;
    if (isDetailsLoading) return <div>Loading competition details...</div>;
    if (isDetailsError) return (
        <div>
            Error loading competition details
            {
                competitionDetailsQueries.map((query) => {
                    return (<p>{query.error?.message}</p>);
                })
            }
        </div>);


    if (isBibsLoading) return <div>Loading competition details...</div>;
    if (isBibsError) return (
        <div>
            Error loading competition details
            {
                competitionBibsQueries.map((query) => {
                    return (<p>{query.error?.message}</p>);
                })
            }
        </div>);

    const competition_data_list = competitionDetailsQueries.map(q => q.data as Competition);

    const bibs_list_array = competitionBibsQueries.map((q) => q.data ?? { bibs: [] });

    return (
        <>
            <BibListEventAdmin competition_list={competition_list as CompetitionIdList} competition_data_list={competition_data_list} bibs_list_array={bibs_list_array} />
        </>
    );
}