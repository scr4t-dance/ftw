import { ArtefactDescription, Phase, YanArtefact } from 'hookgen/model';
import React, { useState } from 'react';

export function ArtefactFormElement({ attribute_name, artefact_value, callback }: { attribute_name: string; artefact_value: ArtefactDescription; callback: React.Dispatch<React.SetStateAction<Phase>>; }) {

    const [artefact, setArtefact] = useState<ArtefactDescription>(artefact_value);

    const default_yan_weights = {yes:3, alt:2, no:1};
    const defaultArtefact: YanArtefact = { "test": default_yan_weights };
    const handleInputChange = (event: React.ChangeEvent<HTMLSelectElement | HTMLInputElement>) => {
        const { name, value } = event.target;

        if (name === "artefact") {

            setArtefact((prev) => {
                let updated_prev = { ...prev };

                if (value === "Ranking") {
                    updated_prev = [value, 'RPSS'];
                } else if (value === "Yan") {
                    updated_prev = [value, defaultArtefact];
                }

                console.log(updated_prev);
                return updated_prev;

            });
        } else {
            setArtefact((prev) => ({
                ...prev,
                [name]: value
            }));
        }

        callback((prevPhase: Phase) => {

            return {
                ...prevPhase,
                [attribute_name]: artefact,
            };
        });
    };

    const handleYanCriterionChange = (
        key: string,
        field: 'newkey' | 'key' | 'yes' | 'alt' | 'no',
        value: string
    ) => {

        console.log(key, field, value);

        if (field === 'newkey') {
            setArtefact((prev: ArtefactDescription) => {
                if (!prev[1]) {
                    return prev;
                }
                const updatedCriterion = prev[1] as YanArtefact;
                updatedCriterion[key] = default_yan_weights;


                console.log("Updated YanArtefact newkey", {
                    ...artefact,
                    yan_criterion: updatedCriterion
                });
                return [prev[0], updatedCriterion];
            });
        } else if (field === 'key') {
            setArtefact((prev: ArtefactDescription) => {
                if (!prev[1]) {
                    return prev;
                }

                const updatedCriterion = prev[1] as YanArtefact;
                updatedCriterion[value] = updatedCriterion[key];
                delete updatedCriterion[key];

                return {
                    ...artefact,
                    yan_criterion: updatedCriterion
                };
            });
        } else if (['yes', 'alt', 'no'].includes(field)) {
            setArtefact((prev: ArtefactDescription) => {
                if (!prev[1]) {
                    return prev;
                }

                const numberValue = parseInt(value);
                const yan_artefact = prev[1] as YanArtefact

                if (!yan_artefact[key]) {
                    yan_artefact[key] = default_yan_weights;
                }

                const updatedCriterion = prev[1] as YanArtefact;
                updatedCriterion[key][field] = numberValue;

                console.log("Updated YanArtefact", updatedCriterion);

                return {
                    ...artefact,
                    yan_criterion: updatedCriterion
                };
            });
        }


        callback((prevPhase: Phase) => {

            return {
                ...prevPhase,
                [attribute_name]: artefact,
            };
        });

    };


    return (
        <>
            <div className="form_subelem">
                <label>Type d'artefact</label>
                <select
                    name="artefact"
                    value={artefact[0] as string}
                    onChange={handleInputChange}
                    required>
                    {["Yan", "Ranking"].map(key => {
                        return <option key={key} value={key}>{key}</option>;
                    })}
                </select>
            </div>
            {artefact[1] && artefact[0] === "Yan" &&
                <table>
                    <thead>
                        <tr>
                            <th>Critère</th>
                            <th>Yes</th>
                            <th>Alt</th>
                            <th>No</th>
                        </tr>
                    </thead>
                    <tbody>
                        {artefact[1] && Object.entries(artefact[1]).map(([key, { yes, alt, no }], index) => (
                            <tr key={index}>
                                <td>
                                    <input
                                        type="text"
                                        name={key}
                                        value={key || ''}
                                        onChange={(e) => handleYanCriterionChange(key, 'key', e.target.value)} />

                                </td>
                                <td>

                                    <input
                                        type="number"
                                        value={yes || ''}
                                        onChange={(e) => handleYanCriterionChange(key, 'yes', e.target.value)} />
                                </td>
                                <td>
                                    <input
                                        type="number"
                                        value={alt || ''}
                                        onChange={(e) => handleYanCriterionChange(key, 'alt', e.target.value)} />
                                </td>
                                <td>
                                    <input
                                        type="number"
                                        value={no || ''}
                                        onChange={(e) => handleYanCriterionChange(key, 'no', e.target.value)} />
                                </td>
                            </tr>
                        ))}
                        <tr key={Object.keys(artefact[1]).length}>
                            <td>
                                <button type='button' onClick={(e) => handleYanCriterionChange('', 'newkey', '')}>
                                    Add row
                                </button>
                            </td>
                        </tr>
                    </tbody>
                </table>}
            {artefact[1] && artefact[0] === "Ranking" &&
                <>
                    <div>
                        <label>Algorithm for Ranking:</label>
                        <input
                            type="text"
                            name="algorithm_for_ranking"
                            value={artefact[1] as string || ''}
                            onChange={handleInputChange} />
                    </div>
                </>}

        </>
    );

}
