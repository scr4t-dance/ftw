import { ArtefactDescription, ArtefactDescriptionOneOf, Phase, YanArtefactDescription } from 'hookgen/model';
import React, { useEffect, useState } from 'react';

export function ArtefactFormElement({ attribute_name, artefact_value, callback }: { attribute_name: string; artefact_value: ArtefactDescription; callback: React.Dispatch<React.SetStateAction<Phase>>; }) {

    const [artefact, setArtefact] = useState<ArtefactDescription>(artefact_value);

    useEffect(() => {

        callback((prevPhase: Phase) => {
            return {
                ...prevPhase,
                [attribute_name]: artefact,
            };
        });

    }, [artefact, attribute_name, callback])

    const default_yan_weights = { yes: 3, alt: 2, no: 1 };
    const defaultYanArtefact: YanArtefactDescription = { "test": default_yan_weights };

    const handleInputChange = (event: React.ChangeEvent<HTMLSelectElement | HTMLInputElement>) => {
        const { name, value } = event.target;

        console.log(name, value);
        if (name === "artefact") {

            setArtefact((prev) => {
                let updated_prev = { ...prev };

                if (value === "ranking") {
                    updated_prev = { [value]: 'RPSS' };
                } else if (value === "yan") {
                    updated_prev = { [value]: defaultYanArtefact };
                }
                return updated_prev;

            });
        } else {
            setArtefact((prev) => {

                const updated_prev = {
                    ...prev,
                    [name]: value
                };
                return updated_prev;
            });
        }

    };

    const handleYanCriterionChange = (
        key: string,
        field: 'newkey' | 'key' | 'yes' | 'alt' | 'no',
        value: string
    ) => {
        console.log("Change requested:", key, field, value);

        if (field === 'newkey') {
            setArtefact((prev) => {
                const criterion = (prev as ArtefactDescriptionOneOf).yan ?? {};
                const updatedCriterion = {
                    ...criterion,
                    [key]: default_yan_weights
                };

                const updated = { yan: updatedCriterion };
                console.log("Updated artefact (newkey):", updated);

                return updated;
            });

        } else if (field === 'key') {
            setArtefact((prev) => {
                const criterion = (prev as ArtefactDescriptionOneOf).yan ?? {};
                const updatedCriterion = {
                    ...criterion,
                    [value]: criterion[key]
                };
                delete updatedCriterion[key];

                const updated = {
                    ...prev,
                    yan: updatedCriterion
                };

                console.log("Updated artefact (key rename):", updated);

                return updated;
            });

        } else if (['yes', 'alt', 'no'].includes(field)) {
            const numberValue = parseInt(value);

            setArtefact((prev) => {
                const criterion = (prev as ArtefactDescriptionOneOf).yan ?? {};
                const weights = criterion[key] ?? {};
                const updatedWeights = {
                    ...weights,
                    [field]: numberValue
                };
                const updatedCriterion = {
                    ...criterion,
                    [key]: updatedWeights
                };

                const updated = {
                    ...prev,
                    yan: updatedCriterion
                };

                console.log("Updated artefact (weights):", updated);

                return updated;
            });
        }
    };


    return (
        <>
            <div className="form_subelem">
                <label>Type d'artefact</label>
                <select
                    name="artefact"
                    value={Object.keys(artefact)[0]}
                    onChange={handleInputChange}
                    required>
                    {["yan", "ranking"].map(key => {
                        return <option key={key} value={key}>{key}</option>;
                    })}
                </select>
            </div>
            {'yan' in artefact &&
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
                        {artefact.yan && Object.entries(artefact.yan as YanArtefactDescription).map(([key, { yes, alt, no }], index) => (
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
                        <tr>
                            <td>
                                <button type='button' onClick={(e) => handleYanCriterionChange('critere', 'newkey', 'critere')}>
                                    Add row
                                </button>
                            </td>
                        </tr>
                    </tbody>
                </table>}
            {'ranking' in artefact &&
                <>
                    <div>
                        <label>Algorithm for Ranking:</label>
                        <input
                            type="text"
                            name="algorithm_for_ranking"
                            value={artefact.ranking || ''}
                            onChange={handleInputChange} />
                    </div>
                </>}

        </>
    );

}
