import React, { useEffect } from 'react';
// import { useNavigate } from "react-router";
import { useForm, type SubmitHandler, type UseFormReturn, Controller } from 'react-hook-form';
import { useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router';

import { usePutApiCompIdBib, getGetApiCompIdBibsQueryKey, useGetApiCompIdBibs } from '@hookgen/bib/bib'
import {
  type CompetitionId,
  type Bib, type SingleTarget, type CoupleTarget,
  RoleItem,
  type BibList,
  type DancerIdList,
  type DancerId,
} from '@hookgen/model';
import { Field } from '@routes/index/field';

// components/SingleTargetForm.tsx
import { dancerArrayFromTarget } from "@routes/bib/BibComponents";
import { DancerComboBoxComponent } from "@routes/dancer/DancerComponents";
import { useGetApiDancers } from '~/hookgen/dancer/dancer';
import { useGetApiCompId } from '~/hookgen/competition/competition';

export interface CoupleBib extends Omit<Bib, "target"> {
  target: CoupleTarget;
}
export interface SingleBib extends Omit<Bib, "target"> {
  target: SingleTarget;
}

export type BibCoupleTargetForm = UseFormReturn<CoupleBib, any, CoupleBib>;
export type BibSingleTargetForm = UseFormReturn<SingleBib, any, SingleBib>;

interface CoupleTargetFormProps {
  formObject: BibCoupleTargetForm,
  bibs_list: BibList,
}

interface SelectCoupleTargetFormProps {
  formObject: BibCoupleTargetForm,
  follower_id_list: DancerIdWithPrefix[],
  leader_id_list: DancerIdWithPrefix[],
}

interface SingleFormProps {
  formObject: BibSingleTargetForm,
}

interface SingleTargetFormProps {
  formObject: BibSingleTargetForm,
  bibs_list: BibList,
}

interface SelectSingleTargetFormProps {
  formObject: BibSingleTargetForm,
  follower_id_list: DancerIdWithPrefix[],
  leader_id_list: DancerIdWithPrefix[],
}

type DancerIdWithPrefix = { id_dancer: DancerId, prefix: string };

export function get_follower_from_bib(bib: Bib, prefixCallback: (bib: Bib) => string): DancerIdWithPrefix | undefined {

  if (bib.target.target_type === "couple")
    return { id_dancer: bib.target.follower, prefix: prefixCallback(bib) };

  if (bib.target.role[0] === "Follower")
    return { id_dancer: bib.target.target, prefix: prefixCallback(bib) };

  return undefined;
}

export function get_leader_from_bib(bib: Bib, prefixCallback: (bib: Bib) => string): DancerIdWithPrefix | undefined {

  if (bib.target.target_type === "couple")
    return { id_dancer: bib.target.leader, prefix: prefixCallback(bib) };

  if (bib.target.role[0] === "Leader")
    return { id_dancer: bib.target.target, prefix: prefixCallback(bib) };

  return undefined;
}

export function CoupleTargetForm({ formObject, bibs_list }: CoupleTargetFormProps) {
  const {
    register,
    formState: { errors },
  } = formObject;
  return (
    <>
      <Field label="Follower" error={errors.target?.follower?.message}>
        <input
          type="number"
          {...register("target.follower", {
            valueAsNumber: true,
            required: "Le numéro compétiteur doit être renseigné.",
            min: {
              value: 1,
              message: "Le numéro compétiteur doit être un entier strictement positif.",
            },
            validate: {
              checkUniqueness: (t) => {
                return !bibs_list.bibs.filter((b) => b.target.target_type === "couple").flatMap((b) => dancerArrayFromTarget(b.target)).includes(t) || `Dancer ${t} already has a bib`
              }
            }
          })}
        />
      </Field>

      <Field label="Leader" error={errors.target?.leader?.message}>
        <input
          type="number"
          {...register("target.leader", {
            valueAsNumber: true,
            required: "Le numéro compétiteur doit être renseigné.",
            min: {
              value: 0,
              message: "Le numéro compétiteur doit être un entier positif.",
            },
            validate: {
              checkUniqueness: (t) => {
                return !bibs_list.bibs.filter((b) => b.target.target_type === "couple").flatMap((b) => dancerArrayFromTarget(b.target)).includes(t) || `Dancer ${t} already has a bib`
              }
            }
          })}
        />
      </Field>
    </>
  );
}


export function SingleDancerField({ formObject, bibs_list }: SingleTargetFormProps) {

  const {
    register,
    formState: { errors },
  } = formObject;

  return (
    <>
      <Field label="Compétiteurice" error={errors.target?.target?.message}>
        <input
          type="number"
          {...register("target.target", {
            valueAsNumber: true,
            required: "Le numéro compétiteur doit être renseigné.",
            min: {
              value: 1,
              message: "Le numéro compétiteur doit être un entier strictement positif.",
            },
            validate: {
              checkUniqueness: (t) => {
                return !bibs_list.bibs.filter((b) => b.target.target_type === "single").flatMap((b) => dancerArrayFromTarget(b.target)).includes(t) || `Dancer ${t} already has a bib`
              }
            }
          })}
        />
      </Field>
    </>
  );
}


export function RoleField({ formObject }: SingleFormProps) {

  const {
    register,
    formState: { errors },
  } = formObject;

  return (
    <>
      <Field label="Role" error={errors.target?.role?.message}>
        <select multiple {...register("target.role", {
          required: "Veuillez sélectionner au moins un rôle.",
          validate: {

          }
        })}>
          {Object.keys(RoleItem).map((key) => {
            const value = RoleItem[key as keyof typeof RoleItem];
            return (
              <option key={key} value={value}>
                {value}
              </option>
            );
          })}
        </select>
      </Field>
    </>
  );
}


export function SingleTargetForm({ formObject, bibs_list }: SingleTargetFormProps) {

  return (
    <>
      <SingleDancerField formObject={formObject} bibs_list={bibs_list} />

      <RoleField formObject={formObject} />
    </>
  );
}

export function SelectCoupleTargetForm({ formObject, leader_id_list, follower_id_list }: SelectCoupleTargetFormProps) {

  const {
    control,
    formState: { errors, defaultValues },
  } = formObject;

  return (
    <>
      <>
        <Controller
          control={control}
          name={"target.follower"}
          render={({ field }) => (
            <DancerComboBoxComponent
              label="Follower"
              error={errors.target?.follower?.message}
              dancerIdList={{ dancers: follower_id_list.map(d => d.id_dancer) } as DancerIdList}
              selectedItem={field.value}
              onChangeItem={(e) => { field.onChange(e ?? defaultValues?.target?.follower); }}
              prefixArray={follower_id_list.map(d => d.prefix)}
            />
          )}
        />

        <Controller
          control={control}
          name={"target.leader"}
          render={({ field }) => (
            <DancerComboBoxComponent
              label="Leader"
              error={errors.target?.leader?.message}
              dancerIdList={{ dancers: leader_id_list.map(d => d.id_dancer) } as DancerIdList}
              selectedItem={field.value}
              onChangeItem={(e) => { field.onChange(e ?? defaultValues?.target?.leader); }}
              prefixArray={leader_id_list.map(d => d.prefix)}
            />
          )}
        />
      </>
    </>
  );
}


export function SelectSingleTargetForm({ formObject, leader_id_list, follower_id_list }: SelectSingleTargetFormProps) {

  const {
    control,
    watch,
    formState: { errors, defaultValues },
  } = formObject;

  const role = watch("target.role.0");

  // const follower_select_bibs_list = select_bibs_list.bibs.map(
  //   (b) => get_follower_from_bib(b)
  // ).filter((v) => v != null);
  // const leader_select_bibs_list = select_bibs_list.bibs.map(
  //   (b) => get_leader_from_bib(b)
  // ).filter((v) => v != null);

  const bibList = role === "Leader" ? leader_id_list : follower_id_list;


  return (
    <>
      <>
        <RoleField formObject={formObject} />

        <Controller
          control={control}
          name={"target.target"}
          render={({ field }) => (
            <DancerComboBoxComponent
              label="Leader"
              error={errors.target?.target?.message}
              dancerIdList={{ dancers: bibList.map(d => d.id_dancer) } as DancerIdList}
              selectedItem={field.value}
              onChangeItem={(e) => { field.onChange(e ?? defaultValues?.target?.target); }}
              prefixArray={bibList.map(d => d.prefix)}
            />
          )}
        />
      </>
    </>
  );
}

export function NewBibFormComponent({ id_competition, bibs_list, dancer_list }: { id_competition: CompetitionId, bibs_list: BibList, dancer_list: DancerIdList }) {

  const url = "/admin/dancers/"

  const default_single_target: SingleTarget = { target_type: "single", target: 1, role: [RoleItem.Follower] };
  const default_couple_target: CoupleTarget = { target_type: "couple", follower: 1, leader: 2 };

  const formObject = useForm<Bib>({
    defaultValues: {
      competition: id_competition,
      bib: 100,
      target: default_single_target,
    }
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
  const { data: updatedDancerIdList, mutate: updateBib, isSuccess } = usePutApiCompIdBib({
    mutation: {
      onSuccess: () => {
        queryClient.invalidateQueries({
          queryKey: getGetApiCompIdBibsQueryKey(id_competition),
        });
      },
      onError: (err) => {
        console.error('Error updating competition:', err);
        setError("root.serverError", { message: 'Erreur lors de l’ajout de la compétition.' });
      }
    }
  });

  const targetType = watch("target.target_type");

  const onSubmit: SubmitHandler<Bib> = (data) => {
    updateBib({ id: id_competition, data: data });
  };

  useEffect(() => {
    // Reset the entire 'target' field when 'target.target_type' changes
    reset((prevValues: Bib) => ({
      ...prevValues,
      target: (targetType === "single" ? default_single_target : default_couple_target)
    }));
  }, [targetType, reset]);

  return (
    <>
      <form onSubmit={handleSubmit(onSubmit)} >
        {isSuccess &&
          <div className="success_message">
            <p>
              ✅ Bib ajoutée avec succès.
            </p>
            {updatedDancerIdList.dancers.map((id_d) => (
              <p>
                Mise à jour
                <Link to={`${url}${id_d}`}>Compétiteurice</Link>
              </p>
            ))}
          </div>
        }

        <input type="hidden" {...register("competition", { value: id_competition })} />

        <Field label="Dossard" error={errors.bib?.message}>
          <input type="number" {...register("bib", {
            valueAsNumber: true,
            required: true,
            min: {
              value: 0,
              message: "Le numéro de dossard doit être un entier positif.",
            },
            validate: {
              checkUniqueness: (bib) => {
                return !bibs_list.bibs.map((b) => b.bib).includes(bib) || `Bib ${bib} is already taken`
              },
            }
          })}
          />
        </Field>


        <Field label="Target type" error={errors.target?.target_type?.message}>
          <select {...register("target.target_type")}>
            <option value="single">Single</option>
            <option value="couple">Couple</option>
          </select>
        </Field>

        {targetType === "single" && (
          <SingleTargetForm formObject={formObject as BibSingleTargetForm} bibs_list={bibs_list} />
        )}

        {targetType === "couple" && (
          <CoupleTargetForm formObject={formObject as BibCoupleTargetForm} bibs_list={bibs_list} />
        )}

        {errors.root?.formValidation &&
          <div className="error_message">⚠️ {errors.root.formValidation.message}</div>
        }

        {errors.root?.serverError &&
          <div className="error_message">⚠️ {errors.root.serverError.message}</div>
        }

        <button type="submit" >Inscrire un-e compétiteurice</button>

      </form >
    </>
  );
}

export function SelectNewBibFormComponent({ id_competition, bibs_list, dancer_list }: { id_competition: CompetitionId, bibs_list: BibList, dancer_list: DancerIdList }) {

  const url = "/admin/dancers/"

  const default_single_target: SingleTarget = { target_type: "single", target: 1, role: [RoleItem.Follower] };
  const default_couple_target: CoupleTarget = { target_type: "couple", follower: 1, leader: 2 };

  const formObject = useForm<Bib>({
    defaultValues: {
      competition: id_competition,
      bib: 100,
      target: default_single_target,
    }
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
  const { data: updatedDancerIdList, mutate: updateBib, isSuccess } = usePutApiCompIdBib({
    mutation: {
      onSuccess: () => {
        queryClient.invalidateQueries({
          queryKey: getGetApiCompIdBibsQueryKey(id_competition),
        });
      },
      onError: (err) => {
        console.error('Error updating competition:', err);
        setError("root.serverError", { message: 'Erreur lors de l’ajout de la compétition.' });
      }
    }
  });

  const targetType = watch("target.target_type");

  const onSubmit: SubmitHandler<Bib> = (data) => {
    updateBib({ id: id_competition, data: data });
  };

  useEffect(() => {
    // Reset the entire 'target' field when 'target.target_type' changes
    reset((prevValues: Bib) => ({
      ...prevValues,
      target: (targetType === "single" ? default_single_target : default_couple_target)
    }));
  }, [targetType, reset]);

  const follower_select_bibs_list = dancer_list.dancers.map(
    (b) => get_follower_from_bib({
      competition: id_competition,
      bib: 100,
      target: { target_type: "single", role: [RoleItem.Follower], target: b }
    }, (_) => "")
  ).filter((v) => v != null);
  const leader_select_bibs_list = dancer_list.dancers.map(
    (b) => get_leader_from_bib({
      competition: id_competition,
      bib: 100,
      target: { target_type: "single", role: [RoleItem.Leader], target: b }
    }, (_) => "")
  ).filter((v) => v != null);

  return (
    <>
      <form onSubmit={handleSubmit(onSubmit)} >
        {isSuccess &&
          <div className="success_message">
            <p>
              ✅ Bib ajoutée avec succès.
            </p>
            {updatedDancerIdList.dancers.map((id_d) => (
              <p>
                Mise à jour
                <Link to={`${url}${id_d}`}>Compétiteurice</Link>
              </p>
            ))}
          </div>
        }

        <input type="hidden" {...register("competition", { value: id_competition })} />

        <Field label="Dossard" error={errors.bib?.message}>
          <input type="number" {...register("bib", {
            valueAsNumber: true,
            required: true,
            min: {
              value: 0,
              message: "Le numéro de dossard doit être un entier positif.",
            },
            validate: {
              checkUniqueness: (bib) => {
                return !bibs_list.bibs.map((b) => b.bib).includes(bib) || `Bib ${bib} is already taken`
              },
            }
          })}
          />
        </Field>


        <Field label="Target type" error={errors.target?.target_type?.message}>
          <select {...register("target.target_type")}>
            <option value="single">Single</option>
            <option value="couple">Couple</option>
          </select>
        </Field>

        {targetType === "single" && (
          <SelectSingleTargetForm
            formObject={formObject as BibSingleTargetForm}
            follower_id_list={follower_select_bibs_list}
            leader_id_list={leader_select_bibs_list} />
        )}

        {targetType === "couple" && (
          <SelectCoupleTargetForm
            formObject={formObject as BibCoupleTargetForm}
            follower_id_list={follower_select_bibs_list}
            leader_id_list={leader_select_bibs_list} />
        )}

        {errors.root?.formValidation &&
          <div className="error_message">⚠️ {errors.root.formValidation.message}</div>
        }

        {errors.root?.serverError &&
          <div className="error_message">⚠️ {errors.root.serverError.message}</div>
        }
        <button type="submit" >Inscrire un-e compétiteurice</button>

      </form >
    </>
  );
}



export function BibFormComponent({ id_competition }: { id_competition: CompetitionId }) {

  const { data: competition_data, isSuccess: isSuccessCompetition } = useGetApiCompId(id_competition);
  const { data: bibs_list, isSuccess: isSuccessBibs } = useGetApiCompIdBibs(id_competition);
  const { data: dancer_list, isSuccess: isSuccessDancers } = useGetApiDancers();

  if (!isSuccessBibs) return (<div>Chargement des dossards</div>);
  if (!isSuccessDancers) return (<div>Chargement danseurs et danseuses</div>);
  if (!isSuccessCompetition) return (<div>Chargement compétition</div>);

  return (
    <>
      <h1>Compétition {competition_data.name}</h1>
      <h2>Ajouter une compétiteurice</h2>
      <SelectNewBibFormComponent id_competition={id_competition} bibs_list={bibs_list} dancer_list={dancer_list} />
    </>
  );
}