import React, { useState } from 'react';
// import { useNavigate } from "react-router";


import PageTitle from "@routes/index/PageTitle";
import Header from "@routes/header/header";
import Footer from "@routes/footer/footer";
import NewCompetitionForm from './NewCompetitionForm';

function NewCompetitionFormPage(){

    return (
        <>
            <PageTitle title="Nouvelle compétition" />
            <Header />

            <NewCompetitionForm id_event={-1} />

            <Footer />
        </>
    );

}

export default NewCompetitionFormPage;