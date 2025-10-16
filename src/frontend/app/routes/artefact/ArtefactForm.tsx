import React, { useEffect, useRef, useState } from 'react';

import type {
	Artefact, ArtefactDescription, ArtefactYans, Bib, BibList, CompetitionId, DancerId,
	HeatTargetJudgeArtefactArray, PhaseId, Target
} from "@hookgen/model";
import { YanItem } from "@hookgen/model";
import { useParams } from "react-router";
import { useGetApiPhaseId } from "@hookgen/phase/phase";
import { useQueryClient } from "@tanstack/react-query";
import { getGetApiPhaseIdArtefactJudgeIdJudgeQueryKey, useGetApiPhaseIdArtefactJudgeIdJudge, usePutApiPhaseIdArtefactJudgeIdJudge, } from '@hookgen/artefact/artefact';
import { Controller, FormProvider, get, useFieldArray, useForm, useFormContext, type SubmitHandler } from 'react-hook-form';
import { Field } from '@routes/index/field';
import { DancerCell } from '@routes/bib/BibComponents';
import { useGetApiCompIdBibs } from '~/hookgen/bib/bib';

const yan_values: (string | undefined)[] = Object.values(YanItem);

const iter_target_dancers = (t: Target) => t.target_type === "single"
	? [t.target]
	: [t.follower, t.leader];

type validateArtefactProps = {
	htjaArray: HeatTargetJudgeArtefactArray,
	artefact_description: ArtefactDescription
};

function clean_artefact(artefact: Artefact | null): Artefact | null {

	if (artefact == null) return null;

	if (artefact.artefact_type === "ranking") return artefact;
	const has_no_problems = artefact.artefact_data.every((yan) => yan && yan.length <= 1 && yan[0] != null);

	return has_no_problems ? {
		...artefact,
		artefact_data: artefact.artefact_data.map((yan) => has_no_problems ? yan : [YanItem.No])
	} : null;
}

function validate_artefacts({ htjaArray, artefact_description }: validateArtefactProps): HeatTargetJudgeArtefactArray {

	const default_artefact_data = artefact_description.artefact === "ranking" ? null
		: artefact_description.artefact_data.map((_) => null);

	const clean_htja_array = {
		artefacts: htjaArray.artefacts
			.map(htja => ({
				...htja,
				artefact: {
					artefact_type: artefact_description.artefact,
					artefact_data: htja.artefact == null ?
						default_artefact_data : htja.artefact?.artefact_data
				} as Artefact,
			}))
			.map(
				htja => ({
					...htja,
					artefact: clean_artefact(htja.artefact),
				})
			),
	} satisfies HeatTargetJudgeArtefactArray;

	return clean_htja_array;
}

function RankingInput({ form_key }: { form_key: `artefacts.${number}.artefact.artefact_data` }) {
	const {
		register,
		formState: { errors }
	} = useFormContext<HeatTargetJudgeArtefactArray>();

	return (
		<Field
			error={get(errors, `${form_key}.message`)}
		>
			<input
				type="number"
				{...register(`${form_key}`, {
					min: 0,
					valueAsNumber: true,
				})}
			/>
		</Field>
	);
}

type YanCheckboxProps = {
	yan: string, value: string, updateCallback: (v: string | null) => void
};

function YanCheckbox({ yan, value, updateCallback }: YanCheckboxProps) {

	console.log("yancheckbox", yan,  value);

	return (
		<>
			<input type="checkbox"
				checked={yan === value}
				onChange={() => {
					if (yan === value) {
						updateCallback(null);
						return;
					}
					updateCallback(yan);
				}}
			/>{yan}
		</>
	);
}

function YanDropDownInput({ form_key }: { form_key: `artefacts.${number}.artefact.artefact_data.${number}` }) {
	const {
		control,
		formState: { errors }
	} = useFormContext<HeatTargetJudgeArtefactArray>();

	return (
		<Field
			error={get(errors, `${form_key}.0.message`)}
		>
			<Controller
				control={control}
				name={`${form_key}.0`}
				render={({ field }) => (
					<>
						<label className='btn_radio_judge_form yan_yes'>
							<YanCheckbox yan={YanItem.Yes} value={field.value ?? ''} updateCallback={(v) => field.onChange(v)} />
						</label>
						<label className='btn_radio_judge_form yan_alt'>
							<YanCheckbox yan={YanItem.Alt} value={field.value ?? ''} updateCallback={(v) => field.onChange(v)} />
						</label>
						<label className='btn_radio_judge_form yan_no'>
							<YanCheckbox yan={YanItem.No} value={field.value ?? ''} updateCallback={(v) => field.onChange(v)} />
						</label>
					</>
				)}
			/>
		</Field>
	);
}

function YanNumberInput({ form_key }: { form_key: `artefacts.${number}.artefact.artefact_data.${number}` }) {

	const {
		control,
		watch,
		formState: { errors }
	} = useFormContext<HeatTargetJudgeArtefactArray>();

	const yanOrder: (YanItem)[] = [YanItem.No, YanItem.Alt, YanItem.Yes];

	const numberToYanItem = Object.fromEntries(
		yanOrder.map((item, idx) => [idx + 1, item])
	) as Record<number, YanItem>;

	const yanItemToNumber = Object.fromEntries(
		yanOrder.map((item, idx) => [item, idx + 1])
	) as Record<YanItem, number>;

	const fieldValue = watch(form_key);
	const firstItem = Array.isArray(fieldValue) && fieldValue[0] ? fieldValue[0] : undefined;
	const displayValue = firstItem ? yanItemToNumber[firstItem] : "";

	return (
		<Field
			error={get(errors, `${form_key}.message`)}
		>
			<Controller
				control={control}
				name={form_key}
				render={({ field }) => (
					<input
						type="number"
						value={displayValue}
						max={3}
						onChange={(e) => {
							const val = e.target.value;
							if (!val) {
								field.onChange([]); // to avoid making component uncontrolled
							} else {
								const num = Number(val);
								field.onChange(numberToYanItem[num] ? [numberToYanItem[num]] : []);
							}
						}}
					/>
				)}
			/>
		</Field>
	);
}

function ArtefactValidCount({ artefactData }: { artefactData: HeatTargetJudgeArtefactArray }) {

	const artefact_description = artefactData.artefacts[0].heat_target_judge.description;
	const validArtefacts = validate_artefacts({ htjaArray: artefactData, artefact_description: artefact_description });

	if (artefact_description.artefact === "ranking") {
		const ranking_artefact_count = [...new Set(
			validArtefacts.artefacts.filter((htja) => htja.artefact != null).map((htja) => (htja.artefact?.artefact_data))
		)].length;

		return (
			<div className='yan_table'>
				<table>
					<tbody>
						<tr>
							<th>Number of unique ranks</th>
						</tr>
						<tr>
							<td>{ranking_artefact_count}</td>
						</tr>
					</tbody>
				</table>
			</div>
		);

	}

	const yan_artefact_count = Object.keys(YanItem).map((yan) => (
		artefact_description.artefact_data.map((_criterion, index) => (
			validArtefacts.artefacts.filter((htja) => htja.artefact != null).filter((htja) => {
				const artefact = (htja.artefact as ArtefactYans)
				return artefact.artefact_data[index] && (artefact.artefact_data[index][0] === yan);
			}).length
		))
	));

	return (
		<div className='yan_table'>
			<table>
				<tbody>
					<tr>
						<th>Criterion</th>
						{artefact_description.artefact_data.map((criterion, index) => {
							return (
								<th key={`yan.${index}`}>
									{criterion}
								</th>
							);
						})}
					</tr>
					{Object.keys(YanItem).map((yan, index) => (
						<tr>
							<td>{yan}</td>
							{yan_artefact_count[index].map((criterion_count) => (
								<td>
									{criterion_count}
								</td>
							))}
						</tr>
					))}
				</tbody>
			</table>
		</div >
	);

}

type RankingArtefactFormTableProps = {
	artefactData: HeatTargetJudgeArtefactArray,
	heat_number: number | undefined,
	artefactInput: boolean,
	dataBibs: BibList,
};
function RankingArtefactFormTable({ artefactData, heat_number, artefactInput, dataBibs }: RankingArtefactFormTableProps) {

	const artefact_description = artefactData.artefacts[0].heat_target_judge.description;

	const isHeatView = !(heat_number === undefined);

	const formObject = useFormContext<HeatTargetJudgeArtefactArray>();

	const {
		control,
		register,
		setValue,
		formState: { errors, defaultValues } } = formObject;

	const { fields, update } = useFieldArray({
		control,
		name: "artefacts",
	});

	const sortedDefaultFields = React.useMemo(() => {
		if (!defaultValues?.artefacts) return fields.map((f, i) => ({ field: f, originalIndex: i }));

		//console.log("defualt ", defaultValues.artefacts?.[0]?.artefact);

		return [...fields]
			.map((field, index) => {
				const defaultArtefact = defaultValues.artefacts?.[index]?.artefact;
				const sortValue =
					defaultArtefact?.artefact_type === "ranking"
						? (defaultArtefact?.artefact_data ?? 0)
						: 0;

				return { field: field, _sortValue: sortValue, originalIndex: index };
			})
			.sort((a, b) => {
				if (a._sortValue === b._sortValue) {
					return a.originalIndex - b.originalIndex;
				}
				return a._sortValue - b._sortValue;
			});
	}, [fields, defaultValues]);

	const ordered_fields = artefactInput ? fields.map((f, i) => ({ field: f, originalIndex: i })) : sortedDefaultFields;

	const moveUp = (index: number) => {

		const rank = ordered_fields[index].field.artefact?.artefact_type === "ranking" ? ordered_fields[index].field.artefact?.artefact_data : undefined;
		const hasSameRank = ordered_fields.filter((f) => f.field.artefact?.artefact_data === rank).length > 1;

		const max_rank_array = fields
			.map((f) => f.artefact?.artefact_type === "ranking" ? f.artefact?.artefact_data : 0);
		const max_rank = Math.max(...max_rank_array);

		if (hasSameRank || rank === undefined) {
			// increase rank for all targets of same rank (except target)
			// handle case when target has null rank
			const futureHtjaRank = rank ?? max_rank + 1;

			const newValues = ordered_fields
				.filter((f) => f.field.artefact?.artefact_type === "ranking" && f.field.artefact.artefact_data >= futureHtjaRank && f.originalIndex !== index)
				.map((f) => ({
					index: `artefacts.${f.originalIndex}.artefact.artefact_data` as `artefacts.${number}.artefact.artefact_data`,
					value: (f.field.artefact?.artefact_data as number) + 1,
				}));

			newValues.forEach(({ index, value }) => setValue(index, value));
			setValue(`artefacts.${index}.artefact`, { artefact_type: "ranking", artefact_data: futureHtjaRank });
		} else if (rank ?? 0 > 1) {
			// swap rank with next rank
			const futureHtjaRank = (rank as number) - 1;

			const newValues = ordered_fields
				.filter((f) => f.field.artefact?.artefact_type === "ranking" && f.field.artefact.artefact_data >= futureHtjaRank && f.field.artefact.artefact_data < futureHtjaRank + 2)
				.map((f) => ({
					index: `artefacts.${f.originalIndex}.artefact.artefact_data` as `artefacts.${number}.artefact.artefact_data`,
					value: f.originalIndex === index ? futureHtjaRank : futureHtjaRank + 1,
				}));

			newValues.forEach(({ index, value }) => setValue(index, value));
		}
		console.log("target already at rank 1");

	};

	return (

		<table>
			<tbody>
				<tr>
					<th>Bib</th>
					<th>Target</th>
					<th>Rank</th>
					<th>Move</th>
					<th>Move</th>
				</tr>
				{ordered_fields && ordered_fields.map(({ field, originalIndex: index }) => (
					<>
						{(!isHeatView || (field.heat_target_judge.heat_number === heat_number)) &&

							<tr key={field.id}>
								<td>
									{(dataBibs.bibs.find((bib) => JSON.stringify(bib.target) === JSON.stringify(field.heat_target_judge.target)) as Bib).bib}
								</td>
								<td>
									<p>
										{field.heat_target_judge.target.target_type == "single" &&
											field.heat_target_judge.target.role}
										{field.heat_target_judge.target.target_type == "couple" &&
											"couple"}
									</p>
									{iter_target_dancers(field.heat_target_judge.target).map((i) => (
										<DancerCell key={`bib.${index}`} id_dancer={i} link={false} />
									))}
									<Field
										error={get(errors, `artefacts.${index}.artefact.artefact_type.message`)}
									>
										<input
											type='hidden'
											{...register(`artefacts.${index}.artefact.artefact_type`
											)} />
									</Field>
								</td>
								{field.heat_target_judge.description.artefact === "ranking" &&
									<>
										<td>
											<RankingInput form_key={`artefacts.${index}.artefact.artefact_data`} />
										</td>
										<td>
											<button type='button' onClick={() => moveUp(index)}>Up</button>
										</td>
									</>
								}
							</tr>
						}
					</>
				))}
			</tbody>
		</table>
	);
}

type YanArtefactFormTableProps = {
	artefactData: HeatTargetJudgeArtefactArray,
	heat_number: number | undefined,
	artefactInput: boolean,
	dataBibs: BibList,
};

function YanArtefactFormTable({ artefactData, heat_number, artefactInput, dataBibs }: YanArtefactFormTableProps) {

	const artefact_description = artefactData.artefacts[0].heat_target_judge.description;

	if (artefact_description.artefact !== "yan") return <p>Wrong artefact type</p>;

	const isHeatView = !(heat_number === undefined);

	const formObject = useFormContext<HeatTargetJudgeArtefactArray>();

	const {
		control,
		register,
		formState: { errors } } = formObject;

	const { fields } = useFieldArray({
		control,
		name: "artefacts",
	});

	return (

		<table>
			<tbody>
				<tr>
					<th>Bib & target</th>
					{artefact_description.artefact_data.map((criterion, index) => {
						return (
							<th key={`yan.${index}`}>
								{criterion}
							</th>
						);
					})}
				</tr>
				{fields && fields.map((field, index) => (
					<>
						{(!isHeatView || (field.heat_target_judge.heat_number === heat_number)) &&

							<tr key={field.id} className={index%2===0?"odd-row":"even-row"}>
								<td className="table_comp_target">
									<div className="row">
										<p className="table_comp_bib">
											{(dataBibs.bibs.find((bib) => JSON.stringify(bib.target) === JSON.stringify(field.heat_target_judge.target)) as Bib).bib}
										</p>
										<p className="table_comp_role">(
											{field.heat_target_judge.target.target_type == "single" &&
												field.heat_target_judge.target.role}
											{field.heat_target_judge.target.target_type == "couple" &&
												"couple"})
										</p>
									</div>
									<p className="table_comp_dancer_name">
										{iter_target_dancers(field.heat_target_judge.target).map((i) => (
											<DancerCell key={`bib.${index}`} id_dancer={i} />
										))}
										<Field
											error={get(errors, `artefacts.${index}.artefact.artefact_type.message`)}
										>
											<input
												type='hidden'
												{...register(`artefacts.${index}.artefact.artefact_type`
												)} />
										</Field>
									</p>
								</td>
								{field.heat_target_judge.description.artefact === "yan" &&
									field.heat_target_judge.description.artefact_data.map((_, c_index) => {
										return (
											<td className="table_comp_res">
												{artefactInput &&
													<YanNumberInput form_key={`artefacts.${index}.artefact.artefact_data.${c_index}`} />
												}
												{!artefactInput &&
													<YanDropDownInput form_key={`artefacts.${index}.artefact.artefact_data.${c_index}`} />
												}
											</td>
										);
									})}
								{field.heat_target_judge.description.artefact !== "yan" &&
									<td>Unexpected artefact type in input</td>
								}
							</tr>
						}
					</>
				))}
			</tbody>
		</table>
	);
}

type ArtefactFormComponentProps = {
	artefactData: HeatTargetJudgeArtefactArray,
	dataBibs: BibList,
}
export function ArtefactFormComponent({ artefactData, dataBibs }: ArtefactFormComponentProps) {


	const [isHeatView, setHeatView] = useState(true);
	const [artefactInput, setArtefactInput] = useState(true);

	const phase_id: PhaseId = artefactData.artefacts[0].heat_target_judge.phase_id;
	const judge_id: DancerId = artefactData.artefacts[0].heat_target_judge.judge;
	const artefact_description = artefactData.artefacts[0].heat_target_judge.description;

	const heat_number_array = artefactData.artefacts.map((htja) => (
		htja.heat_target_judge.heat_number
	));
	const unique_heat_number = [...new Set(heat_number_array)];

	const queryClient = useQueryClient();

	const { mutate: mutateArtefacts } = usePutApiPhaseIdArtefactJudgeIdJudge({
		mutation: {
			onSuccess: (_, { data }) => {
				queryClient.invalidateQueries({
					queryKey: getGetApiPhaseIdArtefactJudgeIdJudgeQueryKey(phase_id, judge_id),
				});
				console.log("resetting with data", data);
				reset(data);
			},
			onError: (err) => {
				console.error('Error updating competition:', err);
				setError("root.serverError", { message: 'Erreur lors de l’ajout de la compétition.' });
			}
		}
	});

	const formObject = useForm<HeatTargetJudgeArtefactArray>({
		//disabled: isLoading,
		defaultValues: validate_artefacts({ htjaArray: artefactData, artefact_description: artefact_description }),
	});

	const {
		reset,
		handleSubmit,
		setError,
		getValues,
		formState: { errors } } = formObject;


	const onSubmit: SubmitHandler<HeatTargetJudgeArtefactArray> = (dataArray) => {
		//console.log("raw dataArray", { id: phase_id, data: dataArray });
		const validArtefacts = validate_artefacts({ htjaArray: dataArray, artefact_description: artefact_description });
		//console.log("filtered validArtefacts", { id: phase_id, data: validArtefacts });

		mutateArtefacts({
			id: phase_id,
			idJudge: judge_id,
			data: validArtefacts,
		});
	};


	return (
		<FormProvider {...formObject}>
			<ArtefactValidCount artefactData={getValues()} />
			<div className="buttons_judge_artefact_change_view">
				<button type='button' className="btn colored_btn" onClick={() => setHeatView(!isHeatView)}>Change heat view</button>
				<button type='button' className="btn colored_btn" onClick={() => setArtefactInput(!artefactInput)}>{artefactInput ? "Change form to dropdowns" : "Change form to numbers"}</button>
			</div>
			<form onSubmit={handleSubmit(onSubmit)} className='yan_table' >
				{artefact_description.artefact === "yan" && isHeatView && unique_heat_number && unique_heat_number.map((heat_number) => (
					<>
						<h2>Heat {heat_number}</h2>
						<YanArtefactFormTable
							artefactData={artefactData}
							heat_number={heat_number}
							artefactInput={artefactInput}
							dataBibs={dataBibs}
						/>
					</>

				))}
				{artefact_description.artefact === "yan" && !isHeatView && (
					<>
						<h2>All heats</h2>
						<YanArtefactFormTable
							artefactData={artefactData}
							heat_number={undefined}
							artefactInput={artefactInput}
							dataBibs={dataBibs}
						/>
					</>

				)}
				{artefact_description.artefact === "ranking" && isHeatView && unique_heat_number && unique_heat_number.map((heat_number) => (
					<>
						<h2>Heat {heat_number}</h2>
						<RankingArtefactFormTable
							artefactData={artefactData}
							heat_number={heat_number}
							artefactInput={artefactInput}
							dataBibs={dataBibs} />
					</>

				))}
				{artefact_description.artefact === "ranking" && !isHeatView && (
					<>
						<h2>All heats</h2>
						<RankingArtefactFormTable
							artefactData={artefactData}
							heat_number={undefined}
							artefactInput={artefactInput}
							dataBibs={dataBibs} />
					</>

				)}

				{errors.root?.formValidation &&
					<div className="error_message">⚠️ {errors.root.formValidation.message}</div>
				}

				{errors.root?.serverError &&
					<div className="error_message">⚠️ {errors.root.serverError.message}</div>
				}

				<button type="submit" className="btn" disabled={formObject.formState.isSubmitting}>
					Mettre à jour les artefacts
				</button>
				<button
					className="btn"
					type="button"
					disabled={formObject.formState.isSubmitting}
					onClick={() => reset(artefactData)}>
					Réinitialiser
				</button>

			</form>
		</FormProvider >
	);
}



export default function ArtefactForm() {

	const { id_phase, id_judge, id_competition } = useParams();
	const id_phase_number = Number(id_phase) as PhaseId;
	const id_judge_number = Number(id_judge) as DancerId;
	const id_competition_number = Number(id_competition) as CompetitionId;


	const { data: phaseData, isSuccess: isSuccessPhase } = useGetApiPhaseId(id_phase_number);
	const { data: dataBibs, isSuccess: isSuccessBibs } = useGetApiCompIdBibs(id_competition_number);

	const { data: artefactData, isLoading, isSuccess, isError, error } = useGetApiPhaseIdArtefactJudgeIdJudge(id_phase_number, id_judge_number);
	if (isLoading) return <div>Loading artefacts...</div>;
	if (isError) return (
		<div>
			Error loading artefact data
			{error?.message}
		</div>);
	if (!isSuccess) return <div>Could not load artefacts...</div>;

	if (!isSuccessPhase) return <div>Chargement...</div>;
	if (!phaseData) return null;

	if (!isSuccessBibs) return <div>Chargement...</div>;

	return (
		<>
			<h1>Judge {id_judge_number}</h1>
			<ArtefactFormComponent
				artefactData={artefactData}
				dataBibs={dataBibs}
			/>
		</>
	);
}

export const handle = {
	breadcrumb: () => "Artefact"
};
