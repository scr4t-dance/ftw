// components/CoupleTargetForm.tsx
import { Field } from "@routes/index/field";
import { type UseFormReturn } from "react-hook-form";
import { type Bib, type CoupleTarget } from "@hookgen/model";

export interface CoupleBib extends Omit<Bib, "target"> {
  target: CoupleTarget;
}

interface Props {
  formObject: UseFormReturn<CoupleBib, any, CoupleBib>
}

export function CoupleTargetForm({ formObject }: Props) {
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
