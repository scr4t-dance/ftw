import "~/styles/ContentStyle.css"

import PageTitle from "@routes/index/PageTitle";
import Header from "@routes/header/header";
import Footer from "@routes/footer/footer";
import { Link, useLocation, useParams } from "react-router";
import { useEffect } from "react";
import RulesV0 from "@routes/index/rules/RulesV0";
import RulesV1 from "@routes/index/rules/RulesV1";
import RulesV2 from "@routes/index/rules/RulesV2";



function RenderVersion({rule_id}: {rule_id : string | undefined}) {
    switch (rule_id) {
        case "0": return <RulesV0 />;
        case "1": return <RulesV1 />;
        case "2": return <RulesV2 />;
        default: return <RulesV2 />;
    }
};

function Rules() {

    // scroll to the anchor
    const location = useLocation();

    const { rule_id } = useParams();

    useEffect(() => {
        if (location.hash) {
            const element = document.getElementById(location.hash.substring(1));
            if (element) {
                element.scrollIntoView({ behavior: 'smooth' });
            }
        }
    }, [location]);

    return (
        <>
            <PageTitle title="Règles" />
            <Header />
            <div className="content-container">
                <h1>Les règles du SCR4T</h1>
                <div id="rules-ver-buttons-container">
                    <div className="rules-ver-button btn">
                        <Link to="/rules/2">Règles actuelles</Link>
                    </div>

                    <div className="rules-ver-button btn">
                        <Link to="/rules/1">Règles jusqu'au 09/07/2025</Link>
                    </div>

                    <div className="rules-ver-button btn">
                        <Link to="/rules/0">Règles jusqu'au 31/12/2024</Link>
                    </div>
                </div>

                <RenderVersion rule_id={rule_id} />
            </div>
            <Footer />
        </>
    );
}

export default Rules;