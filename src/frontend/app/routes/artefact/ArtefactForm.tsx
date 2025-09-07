import React, { useState } from 'react';

import type { DancerId, HeatTargetJudgeArtefactArray, PhaseId, Target } from "@hookgen/model";
import { YanItem } from "@hookgen/model";
import { useParams } from "react-router";
import { useGetApiPhaseId } from "@hookgen/phase/phase";
import { useQueryClient } from "@tanstack/react-query";
import { getGetApiPhaseIdArtefactJudgeIdJudgeQueryKey, useGetApiPhaseIdArtefactJudgeIdJudge, usePutApiPhaseIdArtefactJudgeIdJudge, } from '~/hookgen/artefact/artefact';
import { FormProvider, get, useFieldArray, useForm, useFormContext, type SubmitHandler } from 'react-hook-form';
import { Field } from '@routes/index/field';
import { DancerCell } from '@routes/bib/BibList';


export const yan_values: (string | undefined)[] = Object.values(YanItem);

const iter_target_dancers = (t: Target) => t.target_type === "single"
  ? [t.target]
  : [t.follower, t.leader];


export function ArtefactFormTable({ artefactData, heat_number }: { artefactData: HeatTargetJudgeArtefactArray, heat_number: number | undefined }) {

  const artefact_description = artefactData.artefacts[0].heat_target_judge.description;

  const isHeatView = !(heat_number === undefined);

  const formObject = useFormContext<HeatTargetJudgeArtefactArray>();

  const {
    control,
    register,
    formState: { errors } } = formObject;

  const { fields } = useFieldArray({
    control,
    name: "artefacts",
  });

  return (

    <table>
      <tbody>
        <tr>
          <th>Target</th>
          {artefact_description.artefact === "yan" &&
            artefact_description.artefact_data.map((criterion, index) => {
              return (
                <th key={`yan.${index}`}>
                  {criterion}
                </th>
              );
            })}
          {artefact_description.artefact === "ranking" &&
            <th>Rank</th>
          }
        </tr>
        {fields && fields.map((field, index) => (
          <>
            {(!isHeatView || (field.heat_target_judge.heat_number === heat_number)) &&

              <tr key={field.id}>
                <td>
                  <p>
                    {field.heat_target_judge.target.target_type == "single" &&
                      field.heat_target_judge.target.role}
                    {field.heat_target_judge.target.target_type == "couple" &&
                      "couple"}
                  </p>
                  {iter_target_dancers(field.heat_target_judge.target).map((i) => (
                    <DancerCell key={`bib.${index}`} id_dancer={i} />
                  ))}
                </td>
                <Field
                  error={get(errors, `artefacts.${index}.artefact.artefact_type.message`)}
                >
                  <input
                    defaultValue={field.heat_target_judge.description.artefact}
                    type='hidden'
                    {...register(`artefacts.${index}.artefact.artefact_type`
                    )} />
                </Field>

                {field.heat_target_judge.description.artefact === "yan" &&
                  field.heat_target_judge.description.artefact_data.map((_, c_index) => {
                    return (
                      <td>
                        <Field
                          error={get(errors, `artefacts.${index}.artefact.artefact_data.${c_index}.0.message`)}
                        >
                          <select
                            {...register(`artefacts.${index}.artefact.artefact_data.${c_index}.0`)}
                          >
                            {YanItem && Object.keys(YanItem).map(key => {
                              const value = YanItem[key as keyof typeof YanItem];
                              return <option key={key} value={value}>{value}</option>;
                            })}
                          </select>
                        </Field>
                      </td>
                    );
                  })}
              </tr>
            }
          </>
        ))}
      </tbody>
    </table>
  );
}


export function ArtefactFormComponent({ artefactData }: { artefactData: HeatTargetJudgeArtefactArray }) {


  const [isHeatView, setHeatView] = useState(true);

  const phase_id: PhaseId = artefactData.artefacts[0].heat_target_judge.phase_id;
  const judge_id: DancerId = artefactData.artefacts[0].heat_target_judge.judge;

  const heat_number_array = artefactData.artefacts.map((htja) => (
    htja.heat_target_judge.heat_number
  ));
  const unique_heat_number = [...new Set(heat_number_array)];

  const queryClient = useQueryClient();

  const { mutate: mutateArtefacts } = usePutApiPhaseIdArtefactJudgeIdJudge({
    mutation: {
      onSuccess: () => {
        queryClient.invalidateQueries({
          queryKey: getGetApiPhaseIdArtefactJudgeIdJudgeQueryKey(phase_id, judge_id),
        });
      },
      onError: (err) => {
        console.error('Error updating competition:', err);
        setError("root.serverError", { message: 'Erreur lors de l’ajout de la compétition.' });
      }
    }
  });

  const formObject = useForm<HeatTargetJudgeArtefactArray>({
    //disabled: isLoading,
    defaultValues: artefactData
  });

  const {
    reset,
    handleSubmit,
    setError,
    formState: { errors } } = formObject;

  const onSubmit: SubmitHandler<HeatTargetJudgeArtefactArray> = (dataArray) => {
    console.log({ id: phase_id, data: dataArray });
    const validArtefacts = {
      artefacts: dataArray.artefacts.filter(a => {
        if (!a?.artefact?.artefact_type) return false;
        if (!a?.artefact?.artefact_data) return false;

        // keep if at least one criterion is non-empty
        if (a?.artefact?.artefact_type === "ranking") {
          return !a?.artefact?.artefact_data;
        }
        const hasValidData = a.artefact.artefact_data.some(d => d !== undefined && d !== null);
        return hasValidData;
      })
    };
    mutateArtefacts({ id: phase_id, idJudge: judge_id, data: validArtefacts })
  };

  return (
    <FormProvider {...formObject}>
      <button type='button' onClick={() => setHeatView(!isHeatView)}>Change heat view</button>
      <form onSubmit={handleSubmit(onSubmit)} >
        {isHeatView && unique_heat_number.map((heat_number) => (
          <>
            <h2>Heat {heat_number}</h2>
            <ArtefactFormTable artefactData={artefactData} heat_number={heat_number} />
          </>

        ))}
        {!isHeatView && (
          <>
            <h2>All heats</h2>
            <ArtefactFormTable artefactData={artefactData} heat_number={undefined} />
          </>

        )}
        {errors.root?.formValidation &&
          <div className="error_message">⚠️ {errors.root.formValidation.message}</div>
        }

        {errors.root?.serverError &&
          <div className="error_message">⚠️ {errors.root.serverError.message}</div>
        }

        <button type="submit" disabled={formObject.formState.isSubmitting}>
          Mettre à jour les artefacts
        </button>
        <button
          type="button"
          disabled={formObject.formState.isSubmitting}
          onClick={() => reset(artefactData)}>
          Réinitialiser
        </button>

      </form>
    </FormProvider >
  );
}



export default function ArtefactForm() {

  let { id_phase, id_judge } = useParams();
  let id_phase_number = Number(id_phase) as PhaseId;
  let id_judge_number = Number(id_judge) as DancerId;

  const { data: phaseData, isSuccess: isSuccessPhase } = useGetApiPhaseId(id_phase_number);

  const { data: artefactData, isLoading, isSuccess, isError, error } = useGetApiPhaseIdArtefactJudgeIdJudge(id_phase_number, id_judge_number);
  if (isLoading) return <div>Loading artefacts...</div>;
  if (isError) return (
    <div>
      Error loading artefact data
      {error?.message}
    </div>);
  if (!isSuccess) return <div>Could not load artefacts...</div>;

  if (!isSuccessPhase) return <div>Chargement...</div>;
  if (!phaseData) return null;

  return (
    <>
      <h1>Judge {id_judge_number}</h1>
      <ArtefactFormComponent
        artefactData={artefactData}
      />
    </>
  );
}
