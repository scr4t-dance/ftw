import React, { useEffect } from 'react';
// import { useNavigate } from "react-router";
import { useForm, type SubmitHandler, type UseFormReturn } from 'react-hook-form';

import { useGetApiEventIdComps } from '@hookgen/event/event'
import { useGetApiCompId } from '@hookgen/competition/competition';
import { usePutApiCompIdBib, getGetApiCompIdBibsQueryKey} from '@hookgen/bib/bib'


import {
  type CompetitionId,
  type Bib, type SingleTarget, type CoupleTarget,
  RoleItem,
  type EventId,
  type Competition,
  type CompetitionIdList,
} from '@hookgen/model';
import { Field } from '../index/field';
import { type SingleBib, SingleTargetForm } from './SingleTargetForm';
import { type CoupleBib, CoupleTargetForm } from './CoupleTargetForm';
import { useQueryClient } from '@tanstack/react-query';

function NewBibForm({ default_competition = -1 }: { default_competition?: CompetitionId }) {

  // const navigate = useNavigate();

  const default_single_target: SingleTarget = { target_type: "single", target: 1, role: [RoleItem.Follower] };
  const default_couple_target: CoupleTarget = { target_type: "couple", follower: 1, leader: 2 };

  const formObject = useForm<Bib>({
    defaultValues: {
      competition: default_competition,
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
  const { mutate: updateBib, isSuccess } = usePutApiCompIdBib({
    mutation: {
      onSuccess: (data) => {
        console.log("NewBibForm cache", queryClient.getQueryCache().getAll().map(q => q.queryKey));
        queryClient.invalidateQueries({
          queryKey: getGetApiCompIdBibsQueryKey(default_competition),
        });
      },
      onError: (err) => {
        console.error('Error updating competition:', err);
        setError("root.serverError", { message: 'Erreur lors de l’ajout de la compétition.' });
      }
    }
  });

  const { data: dataCompetition } = useGetApiCompId(default_competition);
  const competition = dataCompetition as Competition;
  const { data: dataCompetitionList } = useGetApiEventIdComps(competition?.event as EventId);
  const competition_list = (dataCompetitionList as CompetitionIdList)?.competitions;
  //const { data: dataEventList } = useGetApiEvents();
  //const event_list = dataEventList?.data.events;


  const targetType = watch("target.target_type");

  const onSubmit: SubmitHandler<Bib> = (data) => {
    console.log(data);
    updateBib({ id: default_competition, data: data });
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
      <h1>Ajouter une compétiteurice</h1>
      <form onSubmit={handleSubmit(onSubmit)} >

        {isSuccess &&
          <div className="error_message">
            <span>&#x26A0; </span>
            Successfully added bib
          </div>
        }


        {/* <div className="form_subelem">
                <label>Evénement parent</label>
                <select
                    name="event"
                    value={competition && competition.event}
                    onChange={handleInputChange}
                    required>
                    {event_list && event_list.map((eventId, index) => (
                        <option key={index} value={eventId}>{eventId}</option>
                    ))}
                </select>
            </div> */}

        <Field label="Compétition parent" error={errors.competition?.message}>
          <select
            {...register("competition", { valueAsNumber: true, required: true })}
          >
            {competition_list && competition_list.map((compId, index) => (
              <option key={index} value={compId}>{compId}</option>
            ))}
          </select>
        </Field>

        <Field label="Dossard" error={errors.bib?.message}>
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


        <Field label="Target type" error={errors.target?.target_type?.message}>
          <select {...register("target.target_type")}>
            <option value="single">Single</option>
            <option value="couple">Couple</option>
          </select>
        </Field>

        {targetType === "single" && (
          <SingleTargetForm formObject={formObject as UseFormReturn<SingleBib, any, SingleBib>}/>
        )}

        {targetType === "couple" && (
          <CoupleTargetForm formObject={formObject as UseFormReturn<CoupleBib, any, CoupleBib>} />
        )}

        <button type="submit" >Inscrire un-e compétiteurice</button>

      </form >
    </>
  );
}

export default NewBibForm;
