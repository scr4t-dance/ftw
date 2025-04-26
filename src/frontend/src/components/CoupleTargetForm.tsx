// components/CoupleTargetForm.tsx
import { Field } from "./Field";
import { UseFormRegister, FieldErrors } from "react-hook-form";
import { Bib } from "../hookgen/model";
import { CoupleTarget } from "hookgen/model";

export interface CoupleBib extends Omit<Bib, "target"> {
  target: CoupleTarget;
}

interface Props {
  register: UseFormRegister<CoupleBib>;
  errors: FieldErrors<CoupleBib>;
}

export function CoupleTargetForm({ register, errors }: Props) {
  return (
    <>
      <Field label="Follower" error={errors.target?.follower?.message}>
        <input
          type="number"
          {...register("target.follower", {
            valueAsNumber: true,
            required: "Le numéro compétiteur doit être renseigné.",
            min: {
              value: 0,
              message: "Le numéro compétiteur doit être un entier positif.",
            },
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
          })}
        />
      </Field>
    </>
  );
}
