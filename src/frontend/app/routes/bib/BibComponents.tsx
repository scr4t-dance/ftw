
import React, { useEffect, useState } from 'react';
import { Link } from "react-router";
import { useQueryClient } from "@tanstack/react-query";

import { useGetApiDancerId } from '@hookgen/dancer/dancer';
import {
    type Bib, type BibList, type Competition, type CompetitionId, type CompetitionIdList, type CoupleTarget, type DancerId, RoleItem,
    type SingleTarget, type Target
} from "@hookgen/model";

import { useGetApiCompIdBibs, useDeleteApiCompIdBib, getGetApiCompIdBibsQueryKey, usePatchApiCompIdBib, } from "@hookgen/bib/bib";
import { useForm, type UseFormReturn } from "react-hook-form";
import { Field } from "@routes/index/field";
import { NewTargetBibFormComponent } from './NewBibFormComponent';

const dancerLink = "dancers/"


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

    if (link ?? true) return (<p>{dancer.last_name} {dancer.first_name}</p>);

    return (
        <p>
            <Link to={`/${dancerLink}${id_dancer}`}>
                {dancer.last_name} {dancer.first_name}
            </Link>
        </p>
    )
}

type BibRowReadOnlyProps = {
    bib_object: Bib;
    onEdit: () => void;
    onDelete: () => void
};

function BibRowReadOnly({ bib_object, onEdit, onDelete }: BibRowReadOnlyProps) {

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
                    <DancerCell id_dancer={i} />
                ))
                }
            </td>
            <td>
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
    formObject: UseFormReturn<Bib, any, Bib>;
    onUpdate: () => void;
    onCancel: () => void;
};

function BibRowEditable({ formObject, onUpdate, onCancel }: BibRowEditableProps) {
    const {
        register,
        formState: { errors },
        watch
    } = formObject;

    const targetType = watch("target.target_type");

    return (
        <>
            <td>
                {targetType}
            </td>

            <td>
                <Field label="" error={errors.bib?.message}>
                    <input type="number" {...register("bib", {
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
                    <td><DancerCell id_dancer={formObject.getValues("target.target")} /></td>
                    <td>{formObject.getValues("target.role")?.join(", ")}</td>
                </>
            )}

            {targetType === "couple" && (
                <>
                    <td><DancerCell id_dancer={formObject.getValues("target.follower")} /></td>
                    <td><DancerCell id_dancer={formObject.getValues("target.leader")} /></td>
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


    const [isEditing, setIsEditing] = useState(false);

    const formObject = useForm<Bib>({
        defaultValues: bib_object
    });

    const {
        handleSubmit,
        reset,
        setError,
    } = formObject;

    const queryClient = useQueryClient();

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

    useEffect(() => {
        reset(bib_object);
    }, [bib_object, reset]);

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
            <h1>Liste Compétiteur-ices</h1>
            <table>
                <tbody>
                    <tr>
                        <th>Type target</th>
                        <th>Bib</th>
                        <th>Rôle</th>
                        <th>Target</th>
                        <th>Action</th>
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

type BibListEventAdminComponentProps = {
    competition_list: CompetitionIdList,
    competition_data_list: Competition[],
    bibs_list_array: BibList[]
}

export function BibListEventAdminComponent({ competition_list, competition_data_list, bibs_list_array }: BibListEventAdminComponentProps) {

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

    return (
        <>
            <h1>Liste Compétiteur-ices</h1>
            <table>
                <tbody>
                    <tr>
                        <th>Target</th>
                        {competition_list.competitions.map((id_competition, index) => (
                            <th colSpan={5}>
                                <Link to={`../competitions/${id_competition}`}>{competition_data_list[index].name}</Link>
                            </th>
                        ))}
                    </tr>
                    {dancer_list.map((id_dancer, t_index) => (
                        target_list[t_index].map((target) => (
                            <tr>
                                <td>
                                    <DancerCell id_dancer={id_dancer} />
                                </td>

                                {competition_list.competitions.map((id_competition, index) => {
                                    // target has unique bib per competition
                                    const bib_object = bibs_list_array[index].bibs.find((bib) => (
                                        JSON.stringify(bib.target) === JSON.stringify(target)
                                    ));

                                    if (bib_object === undefined) {
                                        const target = bibs_list_array.flatMap((bl) => bl.bibs.map((b) => b.target)).find((t) => dancerArrayFromTarget(t).includes(id_dancer)) as Target;
                                        return (
                                            <td colSpan={5}>
                                                <NewTargetBibFormComponent id_competition={id_competition} bibs_list={bibs_list_array[index]} target={target} />
                                            </td>
                                        );
                                    }

                                    return <EditableBibDetails bib_object={bib_object} />
                                })}
                            </tr>
                        ))
                    ))}
                    <tr>

                        <td>New</td>
                        {competition_list.competitions.map((id_competition) => (
                            <td colSpan={5}>
                                <Link to={`../competitions/${id_competition}/bibs/new`}>Nouveau bib Compétition {id_competition}</Link>
                            </td>
                        ))}
                    </tr>
                </tbody>
            </table>
        </>
    );
}