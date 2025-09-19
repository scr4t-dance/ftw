import { type RouteConfig, index, prefix, route } from "@react-router/dev/routes";

export default [
  index("routes/home.tsx"),
  route("about", "routes/index/about.tsx"),
  route("faq", "routes/index/faq.tsx"),
  ...prefix("rules", [
    index("routes/index/RulesDefault.tsx"),
    route(":rule_id", "routes/index/Rules.tsx")
  ]),
  route("events", "routes/event/EventHome.tsx", [
    index("routes/event/eventlist.tsx"),
    //route(":id_event", "routes/event/EventDetailsNoForm.tsx"),
    route(":id_event", "routes/event/EventDetails.tsx"),
    route(":id_event/competition_list", "routes/event/EventDetailsNoForm.tsx"),
    route("new", "routes/event/NewEventForm.tsx"),
  ]),
  route("competitions", "routes/competition/CompetitionHome.tsx", [
    route(":id_competition", "routes/competition/CompetitionDetails.tsx"),
    //route("new", "routes/competition/NewCompetitionForm.tsx")
  ]),
  route("dancers", "routes/dancer/DancerHome.tsx", [
    index("routes/dancer/DancerList.tsx"),
    route(":id_dancer", "routes/dancer/DancerPage.tsx"),
    route("new", "routes/dancer/NewDancerForm.tsx"),
  ]),
  route("phases", "routes/phase/PhaseHome.tsx", [
    index("routes/phase/PhaseList.tsx"),
    route(":id_phase","routes/phase/PhasePageHome.tsx", [
      index("routes/phase/PhasePage.tsx"),
      route("heats", "routes/heat/HeatsList.tsx"),
      route("artefacts", "routes/artefact/ArtefactList.tsx"),
      route("judges", "routes/judge/JudgeList.tsx"),
      route("edit_judges", "routes/judge/JudgeForm.tsx"),
      route("artefacts/judge/:id_judge", "routes/artefact/ArtefactForm.tsx"),
    ]),
    route("new", "routes/phase/NewPhaseForm.tsx"),
  ]),

] satisfies RouteConfig;
