import "~/styles/ContentStyle.css";

import React from 'react';

import type { ArtefactDescription } from "@hookgen/model";

function ArtefactDescriptionComponent({ artefact_description }: { artefact_description: ArtefactDescription }) {


    return (
        <>
          {artefact_description.artefact === "yan" &&
            Object.entries(artefact_description.artefact_data as string[]).map(([key], index) => (
              <p key={index}>
                Critère {artefact_description.artefact_data[index]}
              </p>
            ))}

          {artefact_description.artefact === "ranking" && (
            <p>Ranking</p>
          )}
        </>
      );
}


export default ArtefactDescriptionComponent;