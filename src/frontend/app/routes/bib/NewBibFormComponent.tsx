import React, { useEffect } from 'react';
// import { useNavigate } from "react-router";
import { useForm, type SubmitHandler, type UseFormReturn } from 'react-hook-form';
import { useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router';

import { usePutApiCompIdBib, getGetApiCompIdBibsQueryKey } from '@hookgen/bib/bib'
import {
  type CompetitionId,
  type Bib, type SingleTarget, type CoupleTarget,
  RoleItem,
  type BibList,
  type Target,
} from '@hookgen/model';
import { Field } from '@routes/index/field';
import { type SingleBib, SingleTargetForm } from '@routes/bib/SingleTargetForm';
import { type CoupleBib, CoupleTargetForm } from '@routes/bib/CoupleTargetForm';

export function NewBibFormComponent({ id_competition,bibs_list }: { id_competition: CompetitionId, bibs_list:BibList }) {

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
        console.log("NewBibForm cache", queryClient.getQueryCache().getAll().map(q => q.queryKey));
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
          <SingleTargetForm formObject={formObject as UseFormReturn<SingleBib, any, SingleBib>} bibs_list={bibs_list} />
        )}

        {targetType === "couple" && (
          <CoupleTargetForm formObject={formObject as UseFormReturn<CoupleBib, any, CoupleBib>} bibs_list={bibs_list} />
        )}

        <button type="submit" >Inscrire un-e compétiteurice</button>

      </form >
    </>
  );
}


export function NewTargetBibFormComponent({ id_competition,bibs_list, target }: { id_competition: CompetitionId, bibs_list:BibList, target: Target }) {

  const url = "/admin/dancers/"

  const formObject = useForm<Bib>({
    defaultValues: {
      competition: id_competition,
      bib: 100,
      target: target,
    }
  });

  const {
    register,
    handleSubmit,
    setError,
    formState: { errors },
  } = formObject;

  const queryClient = useQueryClient();

  const { data: updatedDancerIdList, mutate: updateBib, isSuccess } = usePutApiCompIdBib({
    mutation: {
      onSuccess: () => {
        console.log("NewBibForm cache", queryClient.getQueryCache().getAll().map(q => q.queryKey));
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

  const onSubmit: SubmitHandler<Bib> = (data) => {
    updateBib({ id: id_competition, data: data });
  };


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


        <input type="hidden" {...register("target", { value: target })} />

        <button type="submit" >Add bib</button>

      </form >
    </>
  );
}
