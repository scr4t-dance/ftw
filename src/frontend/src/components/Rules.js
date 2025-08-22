import "../styles/ContentStyle.css"

import PageTitle from "./PageTitle";
import Header from "./Header"
import Footer from "./Footer";

import { useState, useEffect } from "react";
import { useLocation, useSearchParams } from "react-router-dom";
import RulesV0 from "./rules/RulesV0";
import RulesV1 from "./rules/RulesV1";
import RulesV2 from "./rules/RulesV2";

function Rules() {

    // scroll to the anchor
    const location = useLocation();

    useEffect(() => {
        if (location.hash) {
        const element = document.getElementById(location.hash.substring(1));
        if (element) {
            element.scrollIntoView({ behavior: 'smooth' });
        }
        }
    }, [location]);

    // render the rules version
    const [searchParams, setSearchParams] = useSearchParams();
    const [currentVersion, setCurrentVersion] = useState(1);

    useEffect(() => {
        const version = parseInt(searchParams.get('ver'));
        setCurrentVersion(version);
    }, [searchParams]);

    const changeVersion = (version) => {
        setSearchParams({ ver: version });
    };

    const renderVersion = () => {
        switch (currentVersion) {
            case 0: return <RulesV0 />;
            case 1: return <RulesV1 />;
            case 2: return <RulesV2 />;
            default: return <RulesV2 />;
        }
    };

    return (
        <>
            <PageTitle title="Règles" />
            <Header />
            <div className="content-container">
                <h1>Les règles du SCR4T</h1>

                {renderVersion()}

            </div>
            <Footer />
        </>
    );
}

export default Rules;