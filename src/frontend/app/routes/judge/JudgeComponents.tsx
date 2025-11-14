import React, { useEffect } from 'react';

import type { CouplePanel, DancerId, DancerIdList, Panel, PhaseId, SinglePanel } from "@hookgen/model";
import { Link } from "react-router";
import { Controller, useFieldArray, useFormContext, FormProvider, get, useForm, type SubmitHandler } from 'react-hook-form';

import { Field } from '@routes/index/field';
import { getGetApiPhaseIdJudgesQueryKey, useGetApiPhaseIdJudges, usePutApiPhaseIdJudges } from '@hookgen/judge/judge';
import { useGetApiDancerId } from '~/hookgen/dancer/dancer';
import { useQueryClient } from '@tanstack/react-query';

function sanitizePanel(data: Panel): SinglePanel | CouplePanel {
  if (data.panel_type === "single") {
    const { panel_type, head, followers, leaders } = data as SinglePanel;
    return { panel_type, head, followers, leaders };
  } else {
    const { panel_type, head, couples } = data as CouplePanel;
    return { panel_type, head, couples };
  }
}

type KeysOfType<T, ValueType> = {
  [K in keyof T]: T[K] extends ValueType ? K : never;
}[keyof T];
type JudgeListDescriptionKeys = KeysOfType<SinglePanel, DancerIdList> |
  KeysOfType<CouplePanel, DancerIdList>;

interface Props {
  artefact_description_name: JudgeListDescriptionKeys
}

export function DancerCell({ id_dancer }: { id_dancer: DancerId }) {

  const { data: dancer } = useGetApiDancerId(id_dancer);

  if (!dancer) return "Loading dancer..."

  return (
    <>
      <td>
        <Link to={`/admin/dancers/${id_dancer}`}>
          {dancer.first_name}
        </Link>
      </td>
      <td>
        <Link to={`/admin/dancers/${id_dancer}`}>
          {dancer.last_name}
        </Link>
      </td>
    </>
  )
}

export function JudgeListFormElement({ artefact_description_name }: Props) {

  const {
    register,
    watch,
    control,
    getValues,
    formState: { errors, defaultValues },
  } = useFormContext();

  const { fields, append, remove } = useFieldArray({
    control: control,
    name: `${artefact_description_name}.dancers`,
  });

  const watchFieldArray = watch(`${artefact_description_name}.dancers`);
  const controlledFields = fields.map((field, index) => {
    return {
      ...field,
      ...watchFieldArray[index],
    };
  })


  return (
    <table>
      <thead>
        <tr>
          <th>DancerID</th>
          <th>Prénom</th>
          <th>Nom</th>
        </tr>
      </thead>
      <tbody>
        {fields && fields.map((item, index) => (
          <tr key={item.id}>
            <Controller
              name={`${artefact_description_name}.dancers.${index}`}
              render={({ field }) => (
                <>
                  <td>
                    <Field
                      error={get(errors, `${artefact_description_name}.dancers.${index}.message`)}
                    >
                      <input type="number"
                        value={Number(field.value)}
                        onChange={(e) => {
                          field.onChange(Number(e.target.value));
                        }}
                      />
                    </Field>
                    <button type="button" onClick={() => {
                      remove(index);
                    }}>
                      Delete
                    </button>

                  </td>
                  <DancerCell id_dancer={field.value} />
                </>
              )}
              control={control} />

          </tr>
        ))}
        <tr>
          <td>
            <button
              type="button"
              onClick={() => {
                append(1);
              }}
            >
              append
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  );
}


export function JudgeForm({ id_phase, panel }: { id_phase: PhaseId, panel: Panel }) {

  const queryClient = useQueryClient();

  const { mutate: mutateArtefacts } = usePutApiPhaseIdJudges({
    mutation: {
      onSuccess: () => {
        queryClient.invalidateQueries({
          queryKey: getGetApiPhaseIdJudgesQueryKey(id_phase),
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
    console.log("submit panel", { id: id_phase, data: dataArray });

    const d: Panel = sanitizePanel(dataArray);

    mutateArtefacts({ id: id_phase, data: d })
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

export function JudgeFormComponent({ id_phase }: { id_phase: PhaseId }) {

  const { data, isLoading, } = useGetApiPhaseIdJudges(id_phase);

  if (isLoading) return <div>Chargement...</div>;

  const judgePanel: Panel = data ?? { panel_type: "couple", couples: { dancers: [] } };

  return (
    <>
      <JudgeForm
        id_phase={id_phase}
        panel={judgePanel}
      />
    </>
  );
}

export function JudgeList({ panel_data }: { panel_data: Panel }) {


  return (
    <>
      <h1>Head judge</h1>
      {panel_data.head && (
        <DancerCell id_dancer={panel_data.head} />
      )}
      {panel_data && panel_data.panel_type === "single" && (
        <>
          <p>Followers</p>
          <ul>
            {panel_data.followers && panel_data.followers.dancers.map((judge) => (
              <li>
                <DancerCell id_dancer={judge} />
              </li>
            ))}
          </ul>
          <p>Leaders</p>
          <ul>
            {panel_data.leaders && panel_data.leaders.dancers.map((judge) => (
              <li>
                <DancerCell id_dancer={judge} />
              </li>
            ))}
          </ul>
        </>
      )}

      {panel_data && panel_data.panel_type === "couple" && (
        <>
          <p>Couples</p>
          <ul>
            {panel_data.couples && panel_data.couples.dancers.map((judge) => (
              <li>
                <DancerCell id_dancer={judge} />
              </li>
            ))}
          </ul>
        </>
      )}
    </>
  );
}


export function JudgeListComponent({ id_phase }: { id_phase: PhaseId }) {


  const { data: panel_data, isLoading, isSuccess } = useGetApiPhaseIdJudges(id_phase);

  if (isLoading) return <div>Chargement panel de juge</div>
  if (!isSuccess) return <div>Erreur chargement panel de juge</div>

  return (
    <>
      <JudgeList panel_data={panel_data} />
    </>
  );

}
