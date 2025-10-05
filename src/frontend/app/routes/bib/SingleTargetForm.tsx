// components/SingleTargetForm.tsx
import { Field } from "@routes/index/field";
import { type UseFormReturn } from "react-hook-form";
import { type Bib, type BibList, RoleItem, type SingleTarget } from "@hookgen/model";
import { dancerArrayFromTarget } from "./BibComponents";

export interface SingleBib extends Omit<Bib, "target"> {
  target: SingleTarget;
}


interface FormProps {
  formObject: UseFormReturn<SingleBib, any, SingleBib>,
}

interface Props {
  formObject: UseFormReturn<SingleBib, any, SingleBib>,
  bibs_list: BibList,
}


export function SingleDancerField({ formObject, bibs_list }: Props) {

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
            validate:{
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


export function RoleField({ formObject }: FormProps) {

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


export function SingleTargetForm({ formObject, bibs_list }: Props) {

  return (
    <>
      <SingleDancerField formObject={formObject} bibs_list={bibs_list} />

      <RoleField formObject={formObject} />
    </>
  );
}
