import React from 'react';
import { useForm } from 'react-hook-form';
import { useNavigate } from 'react-router';

import { useGetApiEvents, getGetApiEventIdCompsQueryKey } from '@hookgen/event/event';
import { usePutApiComp } from '@hookgen/competition/competition';

import { KindItem, CategoryItem, type Competition, type EventId, type EventIdList, type CompetitionIdList } from '@hookgen/model';
import { useQueryClient } from '@tanstack/react-query';

function NewCompetitionForm({ id_event }: { id_event: EventId }) {

    const queryClient = useQueryClient();

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
            leaders_count: 50,
            followers_count: 50
        }
    });

    const { data: dataCompetition, mutate: updateCompetition, isError, error, isSuccess } = usePutApiComp({
        mutation: {
            onSuccess: (data) => {
                console.log("NewCompetitionForm cache", queryClient.getQueryCache().getAll().map(q => q.queryKey));
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

    const { data: dataEventList, isLoading } = useGetApiEvents();

    if (isLoading) return <p>Chargement des événements...</p>;
    if (error) return <p>Erreur: {(error as any).message}</p>;

    const event_list = (dataEventList as EventIdList).events;

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
            <p>Default Event {id_event}</p>

            <form onSubmit={handleSubmit(onSubmit)}>
                {isSuccess &&
                    <div className="success_message">
                        ✅ Compétition avec identifiant "{dataCompetition}" ajoutée avec succès.
                    </div>
                }

                <div className="form_subelem">
                    <label>Evénement parent</label>
                    <select {...register("event", { required: true })}>
                        {event_list?.map((eventId, index) => (
                            <option key={index} value={eventId}>
                                {eventId}
                            </option>
                        ))}
                    </select>
                </div>

                <div className="form_subelem">
                    <label>Titre de la compétition</label>
                    <input
                        type="text"
                        {...register("name", { required: "Le nom est requis." })}
                    />
                    {errors.name && <span className="error_message">{errors.name.message}</span>}
                </div>

                <div className="form_subelem">
                    <label>Type de compétition</label>
                    <select {...register("kind.0", { required: true })}>
                        {Object.values(KindItem).map((value) => (
                            <option key={value} value={value}>{value}</option>
                        ))}
                    </select>
                </div>

                <div className="form_subelem">
                    <label>Catégorie de compétition</label>
                    <select {...register("category.0", { required: true })}>
                        {Object.values(CategoryItem).map((value) => (
                            <option key={value} value={value}>{value}</option>
                        ))}
                    </select>
                </div>

                {errors.root?.formValidation &&
                    <div className="error_message">⚠️ {errors.root.formValidation.message}</div>
                }

                {errors.root?.serverError &&
                    <div className="error_message">⚠️ {errors.root.serverError.message}</div>
                }

                <button type="submit">Valider l'événement</button>
            </form>
        </>
    );
}

export default NewCompetitionForm;
