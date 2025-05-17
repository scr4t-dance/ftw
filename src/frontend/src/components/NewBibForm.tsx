import React, { useEffect, useState } from 'react';
// import { useNavigate } from "react-router";
import { useForm, SubmitHandler, UseFormRegister } from 'react-hook-form';

import { useGetApiEventIdComps, useGetApiEvents } from '../hookgen/event/event'
import { usePutApiCompIdBib, useGetApiCompId } from '../hookgen/competition/competition';

import {
  CompetitionId,
  Bib, SingleTarget, CoupleTarget,
  RoleItem,
  EventId,
} from 'hookgen/model';
import { Field } from './Field';
import { SingleBib, SingleTargetForm } from './SingleTargetForm';
import { CoupleBib, CoupleTargetForm } from './CoupleTargetForm';

function NewBibForm({ default_competition = -1 }: { default_competition?: CompetitionId }) {

  // const navigate = useNavigate();

  const default_single_target: SingleTarget = { target_type: "single", target: 1, role: [RoleItem.Follower] };
  const default_couple_target: CoupleTarget = { target_type: "couple", follower: 1, leader: 2 };

  // Using the Orval hook to handle the PUT request
  const { mutate: updateBib, isSuccess } = usePutApiCompIdBib();

  const { data: dataCompetition } = useGetApiCompId(default_competition);
  const competition = dataCompetition?.data;
  const { data: dataCompetitionList } = useGetApiEventIdComps(competition?.event as EventId);
  const competition_list = dataCompetitionList?.data.competitions;
  //const { data: dataEventList } = useGetApiEvents();
  //const event_list = dataEventList?.data.events;

  const {
    register,
    handleSubmit,
    watch,
    reset,

    formState: { errors },
  } = useForm<Bib>({
    defaultValues: {
      competition: default_competition,
      bib: 100,
      target: default_single_target,
    }
  });

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
          <SingleTargetForm register={register as UseFormRegister<SingleBib>} errors={errors} />
        )}

        {targetType === "couple" && (
          <CoupleTargetForm register={register as UseFormRegister<CoupleBib>} errors={errors} />
        )}

        <button type="submit" >Inscrire un-e compétiteurice</button>

      </form >
    </>
  );
}

export default NewBibForm;