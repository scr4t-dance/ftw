import { ArtefactDescription, Phase } from 'hookgen/model';
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

    const defaultYanArtefact: ArtefactDescription = { artefact: "yan",  artefact_data: ["total"] };
    const defaultRankingArtefact: ArtefactDescription = { artefact: "ranking",  artefact_data: null };

    const handleInputChange = (event: React.ChangeEvent<HTMLSelectElement | HTMLInputElement>) => {
        const { name, value } = event.target;

        console.log(name, value);
        if (name === "artefact") {

            setArtefact((prev) => {
                let updated_prev = { ...prev };

                if (value === "ranking") {
                    updated_prev = defaultRankingArtefact;
                } else if (value === "yan") {
                    updated_prev = defaultYanArtefact;
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
                const criterion = (prev).artefact_data ?? [];
                criterion.push(value);

                const updated = { ...prev, artefact_data:criterion };
                console.log("Updated artefact (newkey):", updated);

                return updated;
            });

        } else if (field === 'key') {
            setArtefact((prev) => {
                const criterion = (prev).artefact_data ?? [];
                const updatedCriterion = criterion.map((v) => (v === key) ? value : v);

                const updated = { ...prev, artefact_data:updatedCriterion };
                console.log("Updated artefact (key rename):", updated);

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
            {artefact.artefact === 'yan' &&
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
                        {artefact.artefact_data && artefact.artefact_data.map((key, index) => (
                            <tr key={index}>
                                <td>
                                    <input
                                        type="text"
                                        name={key}
                                        value={key || ''}
                                        onChange={(e) => handleYanCriterionChange(key, 'key', e.target.value)} />

                                </td>
                                <td>yes</td>
                                <td>alt</td>
                                <td>no</td>
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
            {artefact.artefact === 'ranking' &&
                <>
                    <div>
                        <label>Algorithm for Ranking:</label>
                        RPSS
                    </div>
                </>}

        </>
    );

}
