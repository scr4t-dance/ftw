import { type RouteConfig, index, layout, route } from "@react-router/dev/routes";

export default [
  index("routes/home.tsx"),
  route("about", "routes/index/about.tsx"),
  route("events", "routes/event/EventsHome.tsx", [
    index("routes/event/EventList.tsx"),
    route("new", "routes/event/NewEventForm.tsx"),
    //route(":id_event", "routes/event/EventDetailsNoForm.tsx"),
    route(":id_event", "routes/event/EventDetailsHome.tsx", [
      index("routes/event/EventDetails.tsx"),
      route("competitions", "routes/competition/EventCompetitionsHome.tsx", [
        index("routes/competition/CompetitionList.tsx"),
        route("new", "routes/competition/NewCompetitionForm.tsx"),
        route(":id_competition", "routes/competition/CompetitionHome.tsx", [
          index("routes/competition/CompetitionDetails.tsx"),
          route("bibs", "routes/bib/BibList.tsx"),
          route("phases", "routes/phase/PhaseHome.tsx", [
            index("routes/phase/PhaseList.tsx"),
            route("new", "routes/phase/NewPhaseForm.tsx"),
            route(":id_phase", "routes/phase/PhasePageHome.tsx", [
              index("routes/phase/PhasePage.tsx"),
              route("edit", "routes/phase/EditPhaseForm.tsx"),
              route("heats", "routes/heat/HeatsList.tsx"),
              route("artefacts", "routes/artefact/ArtefactList.tsx"),
              route("judges", "routes/judge/JudgeList.tsx"),
              route("edit_judges", "routes/judge/JudgeForm.tsx"),
              route("artefacts/judge/:id_judge", "routes/artefact/ArtefactForm.tsx"),
            ]),
          ]),
        ]),
      ]),
      //route("list", "routes/event/List"),
    ]),
  ]),
  route("dancers", "routes/dancer/DancerHome.tsx", [
    index("routes/dancer/DancerList.tsx"),
    route(":id_dancer", "routes/dancer/DancerPage.tsx"),
    route("new", "routes/dancer/NewDancerForm.tsx"),
  ]),
] satisfies RouteConfig;
