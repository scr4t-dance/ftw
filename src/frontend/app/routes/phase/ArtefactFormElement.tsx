import type { ArtefactDescription, Phase, PhaseId } from '@hookgen/model';
import React, { useEffect } from 'react';
import { FormProvider, get, useFieldArray, useForm, useFormContext, type SubmitHandler } from 'react-hook-form';
import { Field } from '@routes/index/field';
import { useQueryClient } from '@tanstack/react-query';
import { getGetApiPhaseIdQueryKey, useGetApiPhaseId, usePatchApiPhaseId } from '~/hookgen/phase/phase';
import { RankingAlgorithmFormElement } from './RankingAlgorithmFormElement';

type KeysOfType<T, ValueType> = {
    [K in keyof T]: T[K] extends ValueType ? K : never;
}[keyof T];
type PhaseArtefactDescriptionKeys = KeysOfType<Phase, ArtefactDescription>;


const defaultYanWeight = { yes: 3, alt: 2, no: 1 };

const ArtefactDescriptionToWeightsMap = {
    judge_artefact_descr: "weights",
    head_judge_artefact_descr: "head_weights",
};

interface Props {
    artefact_description_name: PhaseArtefactDescriptionKeys
}

function isPhaseCoherent(p: Phase) {
    const identical_artefact = p.head_judge_artefact_descr.artefact === p.judge_artefact_descr.artefact;
    const artefact_coherent_with_algorithm = (p.ranking_algorithm.algorithm === "ranking") ?
        p.judge_artefact_descr.artefact === "ranking" : p.judge_artefact_descr.artefact === "yan";
    return identical_artefact && artefact_coherent_with_algorithm;
}


export function ArtefactFormElement({ artefact_description_name }: Props) {

    const {
        register,
        watch,
        control,
        formState: { errors, defaultValues },
        setValue,
        getValues,
    } = useFormContext();

    const defaultYanArtefact: ArtefactDescription = { artefact: "yan", artefact_data: ["total"] };
    const defaultRankingArtefact: ArtefactDescription = { artefact: "ranking", artefact_data: null };

    const { fields, append, remove } = useFieldArray({
        control: control,
        name: `${artefact_description_name}.artefact_data`,
    });

    const artefactType = watch(`${artefact_description_name}.artefact`);
    const propName = `ranking_algorithm.${ArtefactDescriptionToWeightsMap[artefact_description_name]}`;
    const currentWeights = watch(propName) || [];

    useEffect(() => {
        setValue(
            `${artefact_description_name}.artefact_data`,
            artefactType === "yan"
                ? defaultYanArtefact.artefact_data
                : defaultRankingArtefact.artefact_data,
            { shouldValidate: true, shouldDirty: true }
        );
        setValue(propName, [defaultYanWeight]);
    }, [artefactType, getValues, setValue]);

    return (
        <>
            <Field
                label="Type d'artefact"
                error={get(errors, `${artefact_description_name}.artefact.message`)}
            >
                <select
                    {...register(`${artefact_description_name}.artefact`, {
                        required: "required",
                        validate: (value, formValues) =>
                            isPhaseCoherent(formValues as Phase) || "Artefact description inconsistent with ranking algorithm.",
                    })}
                >
                    {["yan", "ranking"].map(key => {
                        return <option key={key} value={key}>{key}</option>;
                    })}
                </select>
            </Field>
            {artefactType === 'yan' &&
                <table>
                    <thead>
                        <tr>
                            <th>Critère</th>
                            <th>Yes</th>
                            <th>Alt</th>
                            <th>No</th>
                        </tr>
                    </thead>
                    <tbody>
                        {fields && fields.map((key, index) => (
                            <tr key={key.id}>
                                <td>
                                    <Field
                                        error={get(errors, `${artefact_description_name}.artefact_data.${index}.message`)}
                                    >
                                        <input {...register(`${artefact_description_name}.artefact_data.${index}`,
                                            {
                                                required: "Name should not be empty"
                                            }
                                        )} />
                                    </Field>
                                    <button type="button" onClick={() => {
                                        remove(index);

                                        const newWeights = [...currentWeights];
                                        newWeights.splice(index, 1);
                                        setValue(propName, newWeights);

                                    }}>Delete</button>

                                </td>
                                <td>yes</td>
                                <td>alt</td>
                                <td>no</td>
                            </tr>
                        ))}
                        <tr>
                            <td>
                                <button
                                    type="button"
                                    onClick={() => {
                                        append("criterion");

                                        // also add weights
                                        setValue(propName, [...currentWeights, defaultYanWeight]);
                                    }}
                                >
                                    append
                                </button>
                            </td>
                        </tr>
                    </tbody>
                </table>}
            {artefactType === 'ranking' &&
                <>
                    <div>
                        <label>Algorithm for Ranking:</label>
                        RPSS
                    </div>
                </>}
        </>
    );
}



export function EditPhaseForm({ phase_id, phase_data }: { phase_id: PhaseId, phase_data: Phase }) {

    const queryClient = useQueryClient();

    const { mutate: updatePhase, isSuccess: isSuccessPatch } = usePatchApiPhaseId({
        mutation: {
            onSuccess: (updatedPhase) => {

                console.log("Success callback", { id: phase_id, data: updatedPhase });
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdQueryKey(phase_id),
                });

                //reset(updatedPhase);
                //queryClient.setQueryData(getGetApiPhaseIdQueryKey(phase_id), updatedPhase)
            },
            onError: (err) => {
                console.error('Error creating phase:', err);
                setError("root.serverError", { message: 'Erreur lors de l’ajout de la phase.' });
            }
        }
    });

    const formObject = useForm<Phase>({
        mode: "onChange",
        defaultValues: phase_data,
    });

    // guard before form but after queries

    if (!phase_data) {
        return <div>❌ Impossible de charger la phase {phase_id}</div>;
    }
    const onSubmit: SubmitHandler<Phase> = (data) => {
        console.log({ id: phase_id, data: data });
        updatePhase({ id: phase_id, data: data });
    };

    const {
        handleSubmit,
        watch,
        setError,
        reset,
        formState: { errors },
    } = formObject;


    const round = watch("round");


    return (
        <>
            <h1>Modifier la phase</h1>
            <FormProvider {...formObject}>
                <form onSubmit={handleSubmit(onSubmit)}>

                    <h2>Artefact Juges</h2>
                    <ArtefactFormElement artefact_description_name='judge_artefact_descr' />
                    <h2>Artefact Head Juges</h2>
                    <ArtefactFormElement artefact_description_name='head_judge_artefact_descr' />

                    <Field label='Algorithme de ranking'>
                        <RankingAlgorithmFormElement />
                    </Field>

                    {errors.root?.formValidation &&
                        <div className="error_message">⚠️ {errors.root.formValidation.message}</div>
                    }

                    {errors.root?.serverError &&
                        <div className="error_message">⚠️ {errors.root.serverError.message}</div>
                    }

                    <button type="submit" disabled={formObject.formState.isSubmitting}>
                        Mettre à jour la phase
                    </button>
                    <button type="button" disabled={formObject.formState.isSubmitting} onClick={() => reset(phase_data)}>
                        Réinitialiser
                    </button>
                    {isSuccessPatch &&
                        <div className="success_message">
                            ✅ Phase "{round}" avec identifiant "{phase_id}" mis à jour avec succès.
                        </div>
                    }
                </form>
            </FormProvider>
        </>
    );
}

export function EditPhaseFormComponent({ id_phase }: { id_phase: PhaseId }) {

    const { data: phase_data, isLoading: isLoadingGet, isSuccess } = useGetApiPhaseId(id_phase);

    if (isLoadingGet) return <div>Loading Phase {id_phase} data</div>;
    if (!isSuccess) return <div>Error loading Phase {id_phase} data</div>;

    return (<EditPhaseForm phase_id={id_phase} phase_data={phase_data} />);
}
