import React, {useState} from 'react';
import { useNavigate } from "react-router";

import Header from "./Header";
import Footer from "./Footer";
import PageTitle from "./PageTitle";

function NewEventForm() {

    const navigate = useNavigate();

    const [formData, setFormData] = useState({
        title: '',
        date_debut: '',
        date_fin: '',
        forbidden_pairs: '',
    });

    const [error, setError] = useState('');

    const handleSubmit = async (e) => {
        e.preventDefault();

        if (formData.date_debut > formData.date_fin) {
            setError("La date de début doit être antérieure à la date de fin.")

        } else {
            const dataToSend = JSON.stringify(formData);
            // TODO -> call à l'API
            console.log("data:",dataToSend);
            alert(`${dataToSend}`)

            // redirection ?
        }
    }

    return (
        <>
            <PageTitle title="Nouvel événement" />
            <Header />

            <h1>Ajouter un événement</h1>
            <form onSubmit={handleSubmit}>

                <div className="form_subelem">
                    <label>Titre de l'événement</label>
                    <input
                        type="text"
                        name="title"
                        value={formData.title}
                        onChange={(e) => setFormData({...formData, title: e.target.value})}
                        required
                    />
                </div>

                <div className="form_subelem">
                    <label>Début de l'événement</label>
                    <input
                        type="date"
                        name="date_debut"
                        value={formData.date_debut}
                        onChange={(e) => setFormData({...formData, date_debut: e.target.value})}
                        required
                    />
                </div>

                <div className="form_subelem">
                    <label>Fin de l'événement</label>
                    <input
                        type="date"
                        name="date_fin"
                        value={formData.date_fin}
                        onChange={(e) => setFormData({...formData, date_fin: e.target.value})}
                        required
                    />
                </div>

                {error &&
                    <div className="error_message">
                        <span>&#x26A0; </span>
                        {error}
                    </div>
                }

                <button type="submit" >Valider l'événement</button>

            </form>

            <Footer />
        </>
    );
}

export default NewEventForm;