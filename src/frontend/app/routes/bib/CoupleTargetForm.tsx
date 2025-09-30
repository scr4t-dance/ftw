// components/CoupleTargetForm.tsx
import { Field } from "@routes/index/field";
import { type UseFormReturn } from "react-hook-form";
import { type Bib, type BibList, type CoupleTarget } from "@hookgen/model";
import { dancerArrayFromTarget } from "./BibComponents";

export interface CoupleBib extends Omit<Bib, "target"> {
  target: CoupleTarget;
}

interface Props {
  formObject: UseFormReturn<CoupleBib, any, CoupleBib>,
  bibs_list: BibList,
}

export function CoupleTargetForm({ formObject, bibs_list }: Props) {
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
                return !bibs_list.bibs.flatMap((b) => dancerArrayFromTarget(b.target)).includes(t) || `Dancer ${t} already has a bib`
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
            validate:{
              checkUniqueness: (t) => {
                return !bibs_list.bibs.flatMap((b) => dancerArrayFromTarget(b.target)).includes(t) || `Dancer ${t} already has a bib`
              }
            }
          })}
        />
      </Field>
    </>
  );
}
