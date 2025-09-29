import { QueryClient } from "@tanstack/react-query";
import type { CompetitionId, EventId, PhaseId } from "@hookgen/model";
import { getApiEventId, getApiEventIdComps, getGetApiEventIdCompsQueryKey, getGetApiEventIdCompsQueryOptions, getGetApiEventIdQueryKey, getGetApiEventIdQueryOptions } from "@hookgen/event/event";
import { getApiCompId, getGetApiCompIdQueryKey, getGetApiCompIdQueryOptions } from "./hookgen/competition/competition";
import { getApiCompIdBibs, getGetApiCompIdBibsQueryKey, getGetApiCompIdBibsQueryOptions } from "./hookgen/bib/bib";
import { getApiCompIdPhases, getApiPhaseId, getGetApiCompIdPhasesQueryKey, getGetApiCompIdPhasesQueryOptions, getGetApiPhaseIdQueryKey, getGetApiPhaseIdQueryOptions } from "@hookgen/phase/phase";


export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5
    }
  }
});

type WithEventData<T extends object = {}> = T & {
  id_event: number;
  event_data: Event;
};

/* export const eventLoader = {
  serverLoader: async (param: string) => {
    const id_event = Number(param) as EventId;
    return {
      id_event,
      event_data: await getApiEventId(id_event)
    };
  },
  cache: (queryClient: QueryClient, serverData: WithEventData) =>{
    queryClient.setQueryData(getGetApiEventIdQueryKey(serverData.id_event), serverData.event_data);
  },
  clientLoader: async (param: string) => {
    const id_event = Number(param) as EventId;
    return {
      id_event,
      event_data: await queryClient.ensureQueryData(getGetApiEventIdQueryOptions(id_event))
    };
  },

}

type WithCompetitionData<T extends object = {}> = T & {
  id_competition: CompetitionId;
  competition_data: Event;
};

export const competitionLoader = {
  serverLoader: async (param: string) => {
    const id_event = Number(param) as CompetitionId;
    return {
      id_event,
      event_data: await getApiEventId(id_event)
    };
  },
  cache: (queryClient: QueryClient, serverData: WithCompetitionData) =>{
    queryClient.setQueryData(getGetApiCompIdQueryKey(serverData.id_competition), serverData.competition_data);
  },
  clientLoader: async (param: string) => {
    const id_event = Number(param) as EventId;
    return {
      id_event,
      event_data: await queryClient.ensureQueryData(getGetApiCompIdQueryOptions(id_event))
    };
  },
}
 */


export type WithEntityData<
  IdKey extends string,
  DataKey extends string,
  IdType,
  DataType,
  Extra extends object = {},
> = Extra & {
  [K in IdKey]: IdType;
} & {
    [K in DataKey]: DataType;
  };

export type LoaderParam<IdKey extends string> = {
  [K in IdKey]: string; // params come in as strings
};

export type LoaderOutput<
  IdKey extends string,
  DataKey extends string,
  IdType,
  DataType
> = {
  serverLoader: (param: LoaderParam<IdKey>) => Promise<WithEntityData<IdKey, DataKey, IdType, DataType>>,
  cache: (
    queryClient: QueryClient,
    serverData: WithEntityData<IdKey, DataKey, IdType, DataType>
  ) => void,
  clientLoader: (param: LoaderParam<IdKey>) => Promise<WithEntityData<IdKey, DataKey, IdType, DataType>>,
};

export function createLoader<
  IdKey extends string,
  DataKey extends string,
  IdType,
  DataType
>(opts: {
  idKey: IdKey;
  dataKey: DataKey;
  idParser: (param: string) => IdType;
  fetchServer: (id: IdType) => Promise<DataType>;
  getQueryKey: (id: IdType) => Readonly<unknown[]>;
  getQueryOptions: (id: IdType) => any;
  queryClient: QueryClient;
}): LoaderOutput<IdKey, DataKey, IdType, DataType> {
  return {
    serverLoader: async (param) => {
      const id = opts.idParser(param[opts.idKey]);
      console.log("serverLoader", id,)
      return {
        [opts.idKey]: id,
        [opts.dataKey]: await opts.fetchServer(id),
      } as WithEntityData<IdKey, DataKey, IdType, DataType>;
    },
    cache: (
      queryClient, serverData
    ) => {
      queryClient.setQueryData(
        opts.getQueryKey(serverData[opts.idKey]),
        serverData[opts.dataKey]
      );
    },
    clientLoader: async (param) => {
      const id = opts.idParser(param[opts.idKey]);
      return {
        [opts.idKey]: id,
        [opts.dataKey]: await opts.queryClient.ensureQueryData(
          opts.getQueryOptions(id)
        ),
      } as WithEntityData<IdKey, DataKey, IdType, DataType>;
    },
  };
}

type ServerLoaderOutput<L> = L extends LoaderOutput<infer IdKey, infer DataKey, infer IdType, infer DataType>
  ? WithEntityData<IdKey, DataKey, IdType, DataType>
  : never;

type UnionToIntersection<U> =
  (U extends any ? (k: U) => void : never) extends ((k: infer I) => void) ? I : never;

export async function combineServerLoader<L extends LoaderOutput<any, any, any, any>>(loader_array: L[], params: LoaderParam<any>) {
  const results = await Promise.all(
    loader_array.map((l) => l.serverLoader(params))
  );
  const combinedData = results.reduce((acc, cur) => ({ ...acc, ...cur }), {}) as UnionToIntersection<ServerLoaderOutput<L>>;
  return combinedData
}

export async function combineClientLoader<L extends LoaderOutput<any, any, any, any>>(loader_array: L[], params: LoaderParam<any>) {
  const results = await Promise.all(
    loader_array.map((l) => l.clientLoader(params))
  );
  const combinedData = results.reduce((acc, cur) => ({ ...acc, ...cur }), {}) as UnionToIntersection<ServerLoaderOutput<L>>;
  return combinedData
}

// Event loader
export const eventLoader = createLoader({
  idKey: "id_event",
  dataKey: "event_data",
  idParser: (param: string) => Number(param) as EventId,
  fetchServer: getApiEventId,
  getQueryKey: getGetApiEventIdQueryKey,
  getQueryOptions: getGetApiEventIdQueryOptions,
  queryClient,
});

// Competition loader
export const competitionLoader = createLoader({
  idKey: "id_competition",
  dataKey: "competition_data",
  idParser: (param: string) => Number(param) as CompetitionId,
  fetchServer: getApiCompId,
  getQueryKey: getGetApiCompIdQueryKey,
  getQueryOptions: getGetApiCompIdQueryOptions,
  queryClient,
});

export const competitionListLoader = createLoader({
  idKey: "id_event",
  dataKey: "competition_list",
  idParser: (param: string) => Number(param) as EventId,
  fetchServer: getApiEventIdComps,
  getQueryKey: getGetApiEventIdCompsQueryKey,
  getQueryOptions: getGetApiEventIdCompsQueryOptions,
  queryClient,
});


export const bibsListLoader = createLoader({
  idKey: "id_competition",
  dataKey: "bibs_list",
  idParser: (param: string) => Number(param) as CompetitionId,
  fetchServer: getApiCompIdBibs,
  getQueryKey: getGetApiCompIdBibsQueryKey,
  getQueryOptions: getGetApiCompIdBibsQueryOptions,
  queryClient,
});


export const phaseLoader = createLoader({
  idKey: "id_phase",
  dataKey: "phase_data",
  idParser: (param: string) => Number(param) as PhaseId,
  fetchServer: getApiPhaseId,
  getQueryKey: getGetApiPhaseIdQueryKey,
  getQueryOptions: getGetApiPhaseIdQueryOptions,
  queryClient,
});


export const phaseListLoader = createLoader({
  idKey: "id_competition",
  dataKey: "phase_list",
  idParser: (param: string) => Number(param) as CompetitionId,
  fetchServer: getApiCompIdPhases,
  getQueryKey: getGetApiCompIdPhasesQueryKey,
  getQueryOptions: getGetApiCompIdPhasesQueryOptions,
  queryClient,
});
