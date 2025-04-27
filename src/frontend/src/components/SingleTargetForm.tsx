// components/SingleTargetForm.tsx
import { Field } from "./Field";
import { UseFormRegister, FieldErrors } from "react-hook-form";
import { Bib, RoleItem, SingleTarget } from "@hookgen/model";

export interface SingleBib extends Omit<Bib, "target"> {
  target: SingleTarget;
}


interface Props {
  register: UseFormRegister<SingleBib>;
  errors: FieldErrors<SingleBib>;
}

export function SingleTargetForm({ register, errors }: Props) {
  return (
    <>
      <Field label="Compétiteurice" error={errors.target?.target?.message}>
        <input
          type="number"
          {...register("target.target", {
            valueAsNumber: true,
            required: "Le numéro compétiteur doit être renseigné.",
            min: {
              value: 0,
              message: "Le numéro compétiteur doit être un entier positif.",
            },
          })}
        />
      </Field>

      <Field label="Role" error={errors.target?.role?.message}>
        <select multiple {...register("target.role", { required: "Veuillez sélectionner au moins un rôle." })}>
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
