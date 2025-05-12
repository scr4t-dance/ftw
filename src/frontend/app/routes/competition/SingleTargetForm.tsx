// components/SingleTargetForm.tsx
import { Field } from "@routes/index/field";
import { type UseFormRegister, type FieldErrors, type UseFormReturn } from "react-hook-form";
import { type Bib, RoleItem, type SingleTarget } from "@hookgen/model";

export interface SingleBib extends Omit<Bib, "target"> {
  target: SingleTarget;
}


interface Props {

  formObject: UseFormReturn<SingleBib, any, SingleBib>;
}

export function SingleDancerField({ formObject }: Props) {

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
              value: 0,
              message: "Le numéro compétiteur doit être un entier positif.",
            },
          })}
        />
      </Field>
    </>
  );
}


export function RoleField({ formObject }: Props) {

  const {
    register,
    formState: { errors },
  } = formObject;

  return (
    <>
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


export function SingleTargetForm({ formObject }: Props) {

  return (
    <>
      <SingleDancerField formObject={formObject}/>

      <RoleField formObject={formObject} />
    </>
  );
}
