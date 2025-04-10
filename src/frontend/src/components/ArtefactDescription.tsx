import "../styles/ContentStyle.css";

import React from 'react';

import { ArtefactDescription, ArtefactDescriptionOneOf,
    ArtefactDescriptionOneOfTwo, RankingArtefactDescription,
    YanArtefactDescription } from "hookgen/model";
import { Link } from "react-router";

function ArtefactDescriptionComponent({ artefact_description }: { artefact_description: ArtefactDescription }) {

    const yan_descr = (artefact_description as ArtefactDescriptionOneOf).yan;
    const ranking_descr = (artefact_description as ArtefactDescriptionOneOfTwo).ranking;

    return (
        <>
          {yan_descr &&
            Object.entries(yan_descr).map(([key, { yes, alt, no }], index) => (
              <p key={index}>
                Critère {key} — yes: {yes}, alt: {alt}, no: {no}
              </p>
            ))}

          {ranking_descr && (
            <p>{ranking_descr}</p>
          )}
        </>
      );
}


export default ArtefactDescriptionComponent;