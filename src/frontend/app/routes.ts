import { type RouteConfig, index, layout, route } from "@react-router/dev/routes";

export default [
  index("routes/home.tsx"),
  route("about", "routes/index/about.tsx"),
  route("events", "routes/event/eventlist.tsx"),
  route("event", "routes/event/EventHome.tsx", [
    route(":id_event", "routes/event/EventDetails.tsx"),
    route("new", "routes/event/NewEventForm.tsx"),
  ]),
  route("competitions", "routes/competition/CompetitionHome.tsx", [
    route(":id_competition", "routes/competition/CompetitionDetails.tsx"),
    //route("new", "routes/competition/NewCompetitionForm.tsx")
  ]),
  route("dancers", "routes/dancer/DancerList.tsx", [
    route(":id_dancer", "routes/dancer/DancerPage.tsx"),
    route("new", "routes/dancer/NewDancerForm.tsx"),
  ]),

] satisfies RouteConfig;
