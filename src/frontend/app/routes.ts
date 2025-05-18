import { type RouteConfig, index, layout, route } from "@react-router/dev/routes";

export default [
  index("routes/home.tsx"),
  route("about", "routes/index/about.tsx"),
  route("events", "routes/event/eventlist.tsx"),
  route("event", "routes/event/EventHome.tsx", [
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
  route("phases", "routes/competition/PhaseHome.tsx", [
    index("routes/competition/PhaseList.tsx"),
    route(":id_phase", "routes/competition/PhasePage.tsx"),
    route("new", "routes/competition/NewPhaseForm.tsx"),
  ]),

] satisfies RouteConfig;
