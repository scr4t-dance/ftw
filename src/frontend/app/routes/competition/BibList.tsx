import "~/styles/ContentStyle.css";

import React, { useEffect, useState } from 'react';
import { Link } from "react-router";
import { useQueryClient } from "@tanstack/react-query";

import PageTitle from "@routes/index/PageTitle";
import Header from "@routes/header/header";
import Footer from "@routes/footer/footer";

import { useGetApiDancerId } from '@hookgen/dancer/dancer';
import {
    type Bib, type BibList, type CompetitionId, type CoupleTarget, type Dancer, type DancerId, RoleItem, type SingleTarget, type Target
} from "@hookgen/model";

import { useGetApiCompIdBibs, useDeleteApiCompIdBib, getGetApiCompIdBibsQueryKey, usePatchApiCompIdBib } from "@hookgen/bib/bib";
import { useForm, type SubmitHandler, type UseFormReturn } from "react-hook-form";
import { Field } from "../index/field";
import { RoleField, SingleDancerField, type SingleBib } from "./SingleTargetForm";
import { CoupleTargetForm, type CoupleBib } from "./CoupleTargetForm";


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
                        <EditableBibDetails bib_object={bibObject} index={index} />
                    ))}
                </tbody>
            </table>
        </>
    );
}

function BibDetails({ bib_object, index }: { bib_object: Bib, index: number }) {

    const single_target = bib_object.target as SingleTarget;
    const id = single_target.target as number;
    const { data, isLoading } = useGetApiDancerId(id);
    const queryClient = useQueryClient();

    const { mutate: deleteBib } = useDeleteApiCompIdBib({
        mutation: {
            onSuccess: () => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiCompIdBibsQueryKey(bib_object.competition),
                });
            },
        }
    });

    if (isLoading) return <div>Chargement...</div>;
    if (!data) return null;

    const dancer = data as Dancer;
    return (
        <tr key={index}
            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
            <td>
                <Link to={`/${dancerLink}${single_target.target}`}>
                    {dancer.last_name}
                </Link>
            </td>
            <td>
                <Link to={`/${dancerLink}${id}`}>
                    {dancer.first_name}
                </Link>
            </td>
            <td>{bib_object.bib}</td>
            <td>{single_target.role}</td>
            <td>
                <button
                    type="submit"
                    onClick={() => deleteBib({ id: bib_object.competition, data: bib_object })}

                >
                    Delete
                </button>
            </td>
        </tr>

    );
}

function DancerCell({ id_dancer }: { id_dancer: DancerId }) {

    const { data: dancer } = useGetApiDancerId(id_dancer);

    if (!dancer) return "Loading dancer..."

    return (
        <p>
            <Link to={`/${dancerLink}${id_dancer}`}>
                {dancer.last_name} {dancer.first_name}
            </Link>
        </p>
    )
}

function EditableBibDetails({ bib_object, index }: { bib_object: Bib, index: number }) {


    const [isEditing, setIsEditing] = useState(false);

    const formObject = useForm<Bib>({
        defaultValues: bib_object
    });

    const {
        register,
        handleSubmit,
        watch,
        reset,
        setError,
        formState: { errors },
    } = formObject;
    const queryClient = useQueryClient();
    // Using the Orval hook to handle the PUT request
    const { mutate: updateBib, isSuccess } = usePatchApiCompIdBib({
        mutation: {
            onSuccess: () => {
                console.log("UpdateBibForm cache", queryClient.getQueryCache().getAll().map(q => q.queryKey));
                queryClient.invalidateQueries({
                    queryKey: getGetApiCompIdBibsQueryKey(bib_object.competition),
                });
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

    const targetType = watch("target.target_type");

    const dancer_list = bib_object.target.target_type === "single"
        ? [bib_object.target.target]
        : [bib_object.target.follower, bib_object.target.leader];

    const default_single_target: SingleTarget = bib_object.target.target_type === "single"
        ? bib_object.target
        : { target_type: "single", target: bib_object.target.follower, role: [RoleItem.Follower] };
    const default_couple_target: CoupleTarget = bib_object.target.target_type === "couple"
        ? bib_object.target
        : { target_type: "couple", follower: bib_object.target.target, leader: bib_object.target.target };

    console.log(dancer_list);

    const onSubmit: SubmitHandler<Bib> = (data) => {
        console.log("update bib in table", data);
        updateBib({ id: bib_object.competition, data: data });
    };

    useEffect(() => {
        // Reset the entire 'target' field when 'target.target_type' changes
        reset((prevValues: Bib) => ({
            ...prevValues,
            target: (targetType === "single" ? default_single_target : default_couple_target)
        }));
    }, [targetType, reset]);

    return (
        <tr key={index}
            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>

            {isEditing ? (
                <>
                    <td>
                        <Field label="" error={errors.target?.target_type?.message}>
                            <select {...register("target.target_type")}>
                                <option value="single">Single</option>
                                <option value="couple">Couple</option>
                            </select>
                        </Field>
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
                            <td>
                                <SingleDancerField formObject={formObject as UseFormReturn<SingleBib, any, SingleBib>} />
                            </td>
                            <td>
                                <RoleField formObject={formObject as UseFormReturn<SingleBib, any, SingleBib>} />
                            </td>
                        </>
                    )}

                    {targetType === "couple" && (
                        <CoupleTargetForm formObject={formObject as UseFormReturn<CoupleBib, any, CoupleBib>} />
                    )}
                    <td>
                        <button type="button" onClick={() => { handleSubmit(onSubmit)(); setIsEditing(false) }}>Màj</button>
                        <button type="button" onClick={() => { reset(); setIsEditing(false) }} >Annuler</button>
                    </td>
                </>
            ) : (

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
                        <button type="button" onClick={() => setIsEditing(true)} >Edition</button>
                        <button
                            type="button"
                            onClick={() => deleteBib({ id: bib_object.competition, data: bib_object })}
                        >
                            Delete
                        </button>
                    </td>

                </>
            )
            }
        </tr >

    );
}

function BibListComponent({ id_competition }: { id_competition: CompetitionId }) {

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

function BibList() {

    return (
        <>
            <PageTitle title="Événements" />
            <Header />
            <div className="content-container">

                <Link to={`/${dancerLink}new`}>
                    Créer un-e nouvel-le compétiteur-euse
                </Link>
                <p>Attention, lien unique vers la compétition 1</p>
                <BibListComponent id_competition={1} />
            </div>

            <Footer />
        </>
    );
}

export default BibList;