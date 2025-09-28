import type { Route } from './+types/NewEventForm';
// import { useNavigate } from "react-router";
import { Controller, useForm } from 'react-hook-form';
import { useQueryClient } from '@tanstack/react-query';

import { getApiEvents, getGetApiEventsQueryKey, usePutApiEvent } from '@hookgen/event/event';
import type { Event, Date } from '@hookgen/model';
import { Link } from 'react-router';
import { Field } from '@routes/index/field';


export async function loader({ params }: Route.LoaderArgs) {

    const event_list = await getApiEvents();
    return {
        event_list,
    };
}



export function NewEventForm() {

    const queryClient = useQueryClient();

    // const navigate = useNavigate();

    const {
        register,
        handleSubmit,
        formState: { errors },
        setError,
        control,
    } = useForm<Event>({
        defaultValues: {
            name: '',
            start_date: {
                day: 23,
                month: 9,
                year: 2025,
            },
            end_date: {
                day: 23,
                month: 9,
                year: 2025,
            },
        }
    });

    const formatDate = (date: Date | undefined): string => {
        if (date?.year && date?.month && date?.day) {
            return `${date.year}-${String(date.month).padStart(2, '0')}-${String(date.day).padStart(2, '0')}`;
        }
        return '';
    };

    const { data: dataEvent, mutate: updateEvent, isSuccess } = usePutApiEvent({
        mutation: {
            onSuccess: (data) => {
                console.log("NewEventForm cache", queryClient.getQueryCache().getAll().map(q => q.queryKey));
                queryClient.invalidateQueries({
                    queryKey: getGetApiEventsQueryKey(),
                });
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
                setError("root.serverError", { message: 'Erreur lors de l’ajout de la compétition.' });
            }
        }
    });

    const onSubmit = (data: Event) => {
        if (!data.start_date || !data.end_date) {
            setError("root.formValidation", {
                message: "La date de début et la date de fin sont obligatoires."
            });
            return;
        }

        if (formatDate(data.start_date) > formatDate(data.end_date)) {
            setError("root.formValidation", {
                message: "La date de début doit être antérieure à la date de fin."
            });
            return;
        }

        updateEvent({ data });
    };

    return (
        <>
            <h1>Ajouter un événement</h1>
            <form onSubmit={handleSubmit(onSubmit)}>
                {isSuccess &&
                    <div className="success_message">
                        ✅ Evénement avec identifiant "{dataEvent}" ajouté avec succès.
                        <br />
                        <Link to={`/events/${dataEvent}`}>Accéder à l'événement</Link>
                    </div>
                }

                <Field
                    label="Titre de l'événement"
                    error={errors.name?.message}>
                    <input
                        type="text"
                        {...register("name", { required: "Le nom est requis." })}
                    />
                </Field>

                <Field
                    label="Date de début"
                    error={errors.start_date?.message}><Controller
                        name="start_date"
                        control={control}
                        rules={{ required: 'La date de début est requise.' }}
                        render={({ field }) => (
                            <input
                                type="date"
                                value={field.value ? formatDate(field.value) : ''}
                                onChange={(e) => {
                                    const [year, month, day] = e.target.value
                                        .split('-')
                                        .map(Number);
                                    field.onChange({ year, month, day });
                                }}
                            />
                        )}
                    />
                </Field>

                <Field
                    label="Date de fin"
                    error={errors.end_date?.message}><Controller
                        name="end_date"
                        control={control}
                        rules={{ required: 'La date de fin est requise.' }}
                        render={({ field }) => (
                            <input
                                type="date"
                                value={field.value ? formatDate(field.value) : ''}
                                onChange={(e) => {
                                    const [year, month, day] = e.target.value
                                        .split('-')
                                        .map(Number);
                                    field.onChange({ year, month, day });
                                }}
                            />
                        )}
                    />
                </Field>

                {errors.root?.formValidation &&
                    <div className="error_message">⚠️ {errors.root.formValidation.message}</div>
                }

                {errors.root?.serverError &&
                    <div className="error_message">⚠️ {errors.root.serverError.message}</div>
                }

                <button type="submit" >Valider l'événement</button>

            </form>

        </>
    );
}

export default function NewEventFormRoute({
    loaderData
}: Route.ComponentProps){

    return <NewEventForm />;
}
