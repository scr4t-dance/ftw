import type { Route } from './+types/NewCompetitionForm';
import React from 'react';
import { useForm } from 'react-hook-form';
import { Link, useLocation } from 'react-router';

import { getGetApiEventIdCompsQueryKey, getApiEventId, getApiEventIdComps } from '@hookgen/event/event';
import { usePutApiComp } from '@hookgen/competition/competition';
import { KindItem, CategoryItem, type Competition, type EventId } from '@hookgen/model';
import { Field } from '@routes/index/field';
import { useQueryClient } from '@tanstack/react-query';


export async function loader({ params }: Route.LoaderArgs) {

    let id_event = Number(params.id_event) as EventId;
    const event_data = await getApiEventId(id_event);
    const competition_list = await getApiEventIdComps(id_event);
    return {
        id_event,
        event_data,
        competition_list,
    };
}

export function NewCompetitionForm({ id_event }: { id_event: EventId }) {

    const location = useLocation();
    const url = location.pathname.includes("new") ? "../" : "";

    const {
        register,
        handleSubmit,
        formState: { errors },
        setError,
    } = useForm<Competition>({
        defaultValues: {
            event: id_event,
            name: '',
            kind: [KindItem.Jack_and_Jill],
            category: [CategoryItem.Novice],
            n_leaders: 50,
            n_follows: 50
        }
    });

    const queryClient = useQueryClient();
    const { data: dataCompetition, mutate: updateCompetition, isError, error, isSuccess } = usePutApiComp({
        mutation: {
            onSuccess: (data) => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiEventIdCompsQueryKey(id_event),
                });
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
                setError("root.serverError", { message: 'Erreur lors de l’ajout de la compétition.' });
            }
        }
    });

    const onSubmit = (data: Competition) => {
        if (!data.kind?.length || !data.category?.length) {
            setError("root.formValidation", {
                message: "Le type et la catégorie sont obligatoires."
            });
            return;
        }
        updateCompetition({ data });
    };

    return (
        <>
            <h2>Ajouter une compétition</h2>
            <form onSubmit={handleSubmit(onSubmit)}>
                {isSuccess &&
                    <div className="success_message">
                        ✅ Compétition avec identifiant "{dataCompetition}" ajoutée avec succès.
                        <br />
                        <Link to={`${url}${dataCompetition}`}>Accéder à la compétition</Link>
                    </div>
                }

                <Field
                    label='Titre de la compétition'
                    error={errors.name?.message}
                >
                    <input
                        type="text"
                        {...register("name", { required: "Le nom est requis." })}
                    />
                </Field>

                <Field
                    label='Type de compétition'
                    error={errors.kind?.message}
                >
                    <select {...register("kind.0", { required: true })}>
                        {Object.values(KindItem).map((value) => (
                            <option key={value} value={value}>{value}</option>
                        ))}
                    </select>
                </Field>

                <Field
                    label='Catégorie de compétition'
                    error={errors.category?.message}
                >
                    <select {...register("category.0", { required: true })}>
                        {Object.values(CategoryItem).map((value) => (
                            <option key={value} value={value}>{value}</option>
                        ))}
                    </select>
                </Field>

                {errors.root?.formValidation &&
                    <div className="error_message">⚠️ {errors.root.formValidation.message}</div>
                }

                {errors.root?.serverError &&
                    <div className="error_message">⚠️ {errors.root.serverError.message}</div>
                }

                <button type="submit">Créer la compétition</button>
            </form>
        </>
    );
}



export default function NewCompetitionFormRoute({
    params,
    loaderData
}: Route.ComponentProps) {

    return (
        <>
            <h1>Evénement {loaderData.event_data.name}</h1>
            <NewCompetitionForm id_event={loaderData.id_event} />
        </>
    );
}
