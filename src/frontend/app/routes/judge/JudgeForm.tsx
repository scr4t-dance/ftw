import React, { useEffect } from 'react';

import type { CouplePanel, Panel, PhaseId, SinglePanel} from "@hookgen/model";
import { data, useParams } from "react-router";
import { useQueryClient } from "@tanstack/react-query";
import { FormProvider, get, useForm, type SubmitHandler } from 'react-hook-form';
import { Field } from '@routes/index/field';
import { getGetApiPhaseIdJudgesQueryKey, useGetApiPhaseIdJudges, usePutApiPhaseIdJudges } from '@hookgen/judge/judge';
import { JudgeListFormElement } from '@routes/judge/JudgeListFormElement';

function sanitizePanel(data: Panel): SinglePanel | CouplePanel {
    if (data.panel_type === "single") {
        const { panel_type, head, followers, leaders } = data as SinglePanel;
        return { panel_type, head, followers, leaders };
    } else {
        const { panel_type, head, couples } = data as CouplePanel;
        return { panel_type, head, couples };
    }
}

export function JudgeFormComponent({ phase_id, panel }: { phase_id: PhaseId, panel: Panel }) {

    const queryClient = useQueryClient();

    const { mutate: mutateArtefacts } = usePutApiPhaseIdJudges({
        mutation: {
            onSuccess: () => {
                queryClient.invalidateQueries({
                    queryKey: getGetApiPhaseIdJudgesQueryKey(phase_id),
                });
            },
            onError: (err) => {
                console.error('Error updating competition:', err);
                setError("root.serverError", { message: 'Erreur lors de l’ajout du panel de juges.' });
            }
        }
    });

    const formObject = useForm<Panel>({
        defaultValues: panel
    });

    const {
        register,
        reset,
        handleSubmit,
        setError,
        watch,
        formState: { errors } } = formObject;

    const onSubmit: SubmitHandler<Panel> = (dataArray) => {
        console.log({ id: phase_id, data: dataArray });

        const d = sanitizePanel(dataArray);

        mutateArtefacts({ id: phase_id, data: d })
    };

    const panelType = watch("panel_type");

    return (
        <FormProvider {...formObject}>
            <form onSubmit={handleSubmit(onSubmit)} >
                <Field
                    label="Type de panel"
                    error={get(errors, `target.panel_type.message`)}
                >
                    <select
                        {...register("panel_type", {
                            required: "required",
                        })}
                    >
                        {["single", "couple"].map(key => {
                            return <option key={key} value={key}>{key}</option>;
                        })}
                    </select>
                </Field>

                <Field
                    label="Head judge"
                    error={get(errors, `head.message`)}
                >
                    <input
                        type="number" {...register("head",
                            {
                                valueAsNumber: true,
                            }
                        )}
                    />
                </Field>
                {panelType === "single" && (
                    <>
                    <h3>Followers</h3>
                        <JudgeListFormElement artefact_description_name={"followers"} />
                    <h3>Leaders</h3>
                        <JudgeListFormElement artefact_description_name={"leaders"} />
                    </>
                )}
                {panelType === "couple" && (
                    <>
                    <h3>Couples</h3>
                        <JudgeListFormElement artefact_description_name={"couples"} />
                    </>
                )}

                {errors.root?.formValidation &&
                    <div className="error_message">⚠️ {errors.root.formValidation.message}</div>
                }

                {errors.root?.serverError &&
                    <div className="error_message">⚠️ {errors.root.serverError.message}</div>
                }

                <button type="submit" disabled={formObject.formState.isSubmitting}>
                    Mettre à jour les juges
                </button>
                <button
                    type="button"
                    disabled={formObject.formState.isSubmitting}
                    onClick={() => reset(panel)}>
                    Réinitialiser
                </button>

            </form>
        </FormProvider >
    );
}



export default function JudgeForm() {

    let { id_phase } = useParams();
    let id_phase_number = Number(id_phase) as PhaseId;

    const { data, isLoading, isSuccess: isSuccessPhase } = useGetApiPhaseIdJudges(id_phase_number);


    if (isLoading) return <div>Chargement...</div>;

    const judgePanel: Panel = data ?? { panel_type: "couple", couples: { dancers: [] } };

    return (
        <>
            <JudgeFormComponent
                phase_id={id_phase_number}
                panel={judgePanel}
            />
        </>
    );
}
