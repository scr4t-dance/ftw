import React from 'react';

import type { Route } from './+types/ArtefactFormJudge';
import type { CompetitionId, DancerId, PhaseId } from '~/hookgen/model';
import { dehydrate, QueryClient } from '@tanstack/react-query';
import { getGetApiCompIdBibsQueryOptions } from '~/hookgen/bib/bib';
import { getGetApiPhaseIdArtefactJudgeIdJudgeQueryOptions } from '~/hookgen/artefact/artefact';
import { ArtefactFormJudgeRoute } from '@routes/artefact/ArtefactFormComponents';


export async function loader({ params }: Route.LoaderArgs) {

    const queryClient = new QueryClient();
    const id_competition = Number(params.id_competition) as CompetitionId;
    await queryClient.prefetchQuery(getGetApiCompIdBibsQueryOptions(id_competition));
    const id_phase = Number(params.id_phase) as PhaseId;
    const id_judge = Number(params.id_judge) as DancerId;
    await queryClient.prefetchQuery(getGetApiPhaseIdArtefactJudgeIdJudgeQueryOptions(id_phase, id_judge));

    return { dehydratedState: dehydrate(queryClient) };
}


export default function ArtefactForm({ params }: Route.ComponentProps) {

  const id_phase = Number(params.id_phase) as PhaseId;
  const id_judge = Number(params.id_judge) as DancerId;
  const id_competition = Number(params.id_competition) as CompetitionId;

  return (
    <>
      <ArtefactFormJudgeRoute
        id_phase={id_phase} id_judge={id_judge}
        id_competition={id_competition}
      />
    </>
  );
}

export const handle = {
  breadcrumb: () => "Artefact"
};
