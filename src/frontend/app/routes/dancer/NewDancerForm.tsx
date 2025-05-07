import React, { useState } from 'react';
// import { useNavigate } from "react-router";

import { usePutApiDancer } from '@hookgen/dancer/dancer';

import { DivisionsItem, type Dancer, type Date } from '@hookgen/model';

import PageTitle from "@routes/index/PageTitle";
import Header from "@routes/header/header";
import Footer from "@routes/footer/footer";

function NewDancerFormComponent() {

    // const navigate = useNavigate();

    const [dancer, setDancer] = useState<Dancer>({
        last_name: '',
        first_name: '',
        as_leader: [DivisionsItem.None],
        as_follower: [DivisionsItem.None],
    });

    const formatDate = (date: Date | undefined): string => {
        if (date?.year && date?.month && date?.day) {
            return `${date.year}-${String(date.month).padStart(2, '0')}-${String(date.day).padStart(2, '0')}`;
        }
        return '';
    };

    const [dancerValidationError, setDancerValidationError] = useState('');

    const { mutate: updateDancer, isError, error, isSuccess } = usePutApiDancer();

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
        const { name, value } = e.target;

        console.log(name, value)
        if (name === 'as_follower' || name === 'as_leader') {

            setDancer((prevDancer: Dancer) => ({
                ...prevDancer,
                [name]: [value],
            }));
        } else if (name === 'birthday') {
            const [year, month, day] = value.split('-').map(Number);  // Split the YYYY-MM-DD value

            setDancer((prevDancer: Dancer) => ({
                ...prevDancer,
                [name]: { day, month, year },
            }));
        } else {
            setDancer((prevDancer: Dancer) => ({
                ...prevDancer,
                [name]: value,
            }));
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        setDancerValidationError('')

        try {
            await updateDancer({ data: dancer });
            console.log('Dancer updated successfully!');
        } catch (err) {
            if (err instanceof Error) {
                console.error('Error updating dancer:', err.message);
                setDancerValidationError(err.message);  // Use err.message
            } else {
                // Handle other unexpected error types (fallback to a generic error)
                console.error('Unexpected error:', err);
                setDancerValidationError("An unexpected error occurred.");
            }
        }
    };

    return (
        <>
            <form onSubmit={handleSubmit}>

                {isSuccess &&
                    <div className="error_message">
                        <span>&#x26A0; </span>
                        Successfully added dancer "{dancer.last_name} {dancer.first_name}"
                    </div>
                }

                <div className="form_subelem">
                    <label>Nom</label>
                    <input
                        type="text"
                        name="last_name"
                        value={dancer.last_name}
                        onChange={handleInputChange}
                        required
                    />
                </div>

                <div className="form_subelem">
                    <label>Prénom</label>
                    <input
                        type="text"
                        name="first_name"
                        value={dancer.first_name}
                        onChange={handleInputChange}
                        required
                    />
                </div>


                <div className="form_subelem">
                    <label>Email</label>
                    <input
                        type="text"
                        name="email"
                        value={dancer.email}
                        onChange={handleInputChange}
                    />
                </div>

                <div className="form_subelem">
                    <label>Date de naissance (non obligatoire)</label>
                    <input
                        type="date"
                        name="birthday"
                        value={formatDate(dancer.birthday)}
                        onChange={handleInputChange}
                    />
                </div>


                <div className="form_subelem">
                    <label>Division follower</label>
                    <select
                        name="as_follower"
                        value={dancer.as_follower && dancer.as_follower[0]}
                        onChange={handleInputChange}
                        required>
                        {DivisionsItem && Object.keys(DivisionsItem).map(key => {
                            const value = DivisionsItem[key as keyof typeof DivisionsItem];
                            return <option key={key} value={value}>{value}</option>;
                        })}
                    </select>
                </div>

                <div className="form_subelem">
                    <label>Division leader</label>
                    <select
                        name="as_leader"
                        value={dancer.as_leader && dancer.as_leader[0]}
                        onChange={handleInputChange}
                        required>
                        {DivisionsItem && Object.keys(DivisionsItem).map(key => {
                            const value = DivisionsItem[key as keyof typeof DivisionsItem];
                            return <option key={key} value={value}>{value}</option>;
                        })}
                    </select>
                </div>

                {dancerValidationError !== '' &&
                    <div className="error_message">
                        <span>&#x26A0; </span>
                        {dancerValidationError}
                    </div>
                }
                {isError &&
                    <div className="error_message">
                        <span>&#x26A0; </span>
                        <p>{error.message}</p>
                        <p>{error.response?.data.message}</p>
                    </div>
                }

                <button type="submit" >Valider la création</button>

            </form>

        </>
    );
}


function NewDancerForm() {

    return (
        <>
            <PageTitle title="Création Compétiteurice" />
            <Header />
            <div className="content-container">
                <h1>Ajouter un-e compétiteur-euse</h1>
                <NewDancerFormComponent />
            </div>

            <Footer />
        </>
    );
}


export default NewDancerForm;