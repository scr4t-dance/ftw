import React, { useState } from 'react';
// import { useNavigate } from "react-router";


import Header from "./Header";
import Footer from "./Footer";
import PageTitle from "./PageTitle";
import NewPhaseForm from './NewPhaseForm';

function NewPhaseFormPage(){

    return (
        <>
            <PageTitle title="Nouvelle Phase" />
            <Header />

            <NewPhaseForm />

            <Footer />
        </>
    );

}

export default NewPhaseFormPage;