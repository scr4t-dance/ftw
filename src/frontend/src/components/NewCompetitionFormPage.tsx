import React, { useState } from 'react';
// import { useNavigate } from "react-router";


import Header from "./Header";
import Footer from "./Footer";
import PageTitle from "./PageTitle";
import NewCompetitionForm from './NewCompetitionForm';

function NewCompetitionFormPage(){

    return (
        <>
            <PageTitle title="Nouvelle compétition" />
            <Header />

            <NewCompetitionForm />

            <Footer />
        </>
    );

}

export default NewCompetitionFormPage;