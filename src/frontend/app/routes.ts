import { type RouteConfig, index, prefix, route } from "@react-router/dev/routes";

const disable_admin = (import.meta.env.VITE_DISABLE_ADMIN ?? process.env.VITE_DISABLE_ADMIN) === "true";
console.log("routes", disable_admin, import.meta.env.VITE_DISABLE_ADMIN, process.env.VITE_DISABLE_ADMIN);

const admin_routes = disable_admin ? [] : [
  route("admin", "routes/index/HomeAdmin.tsx", [
    index("routes/index/Admin.tsx"),
    route("events", "routes/event/EventsHomeAdmin.tsx", [
      index("routes/event/EventListAdmin.tsx"),
      route("new", "routes/event/NewEventForm.tsx"),
      route(":id_event", "routes/event/EventDetailsHomeAdmin.tsx", [
        index("routes/event/EventDetailsAdmin.tsx"),
        route("competitions", "routes/competition/EventCompetitionsHomeAdmin.tsx", [
          index("routes/competition/CompetitionListAdmin.tsx"),
          route("new", "routes/competition/NewCompetitionForm.tsx"),
          route(":id_competition", "routes/competition/CompetitionHomeAdmin.tsx", [
            index("routes/competition/CompetitionDetailsAdmin.tsx"),
            route("promotions", "routes/competition/CompetitionPromotionsRoute.tsx"),
            route("bibs", "routes/bib/BibHomeAdmin.tsx", [
              index("routes/bib/BibListAdmin.tsx"),
              route("new", "routes/bib/NewBibForm.tsx"),
            ]),
            route("phases", "routes/phase/PhaseHome.tsx", [
              index("routes/phase/PhaseList.tsx"),
              route("new", "routes/phase/NewPhaseForm.tsx"),
              route(":id_phase", "routes/phase/PhasePageHome.tsx", [
                index("routes/phase/PhasePage.tsx"),
                route("edit", "routes/phase/EditPhaseForm.tsx"),
                route("heats", "routes/heat/HeatsList.tsx"),
                route("artefacts", "routes/artefact/ArtefactHome.tsx", [
                  index("routes/artefact/ArtefactList.tsx"),
                  route("scorer/:id_judge", "routes/artefact/ArtefactForm.tsx"),
                  route("judge/:id_judge", "routes/artefact/ArtefactFormJudge.tsx"),
                ]),
                route("judges", "routes/judge/JudgeList.tsx"),
                route("edit_judges", "routes/judge/JudgeForm.tsx"),
                route("ranks", "routes/artefact/RankList.tsx"),
                route("pairings", "routes/phase/Pairings.tsx"),
              ]),
            ]),
          ]),
        ]),
        route("bibs", "routes/bib/BibEventHomeAdmin.tsx", [
          index("routes/bib/BibListEventAdmin.tsx"),
        ]),
      ]),
    ]),
    route("dancers", "routes/dancer/DancerHome.tsx", [
      index("routes/dancer/DancerList.tsx"),
      route(":id_dancer", "routes/dancer/DancerPage.tsx"),
      route("new", "routes/dancer/NewDancerForm.tsx"),
    ]),
  ]),
];

export default [
  index("routes/home.tsx"),
  route("login", "routes/login.tsx"),
  route("logout", "routes/logout.tsx"),
  route("about", "routes/index/about.tsx"),
  route("faq", "routes/index/faq.tsx"),
  ...prefix("rules", [
    index("routes/index/RulesDefault.tsx"),
    route(":rule_id", "routes/index/Rules.tsx")
  ]),
  ...admin_routes,
  route("events", "routes/event/EventsHomePublic.tsx", [
    index("routes/event/EventListPublic.tsx"),
    //route(":id_event", "routes/event/EventDetailsNoForm.tsx"),
    route(":id_event", "routes/event/EventDetailsHomePublic.tsx", [
      index("routes/event/EventDetailsPublic.tsx"),
      route("competitions", "routes/competition/EventCompetitionsHomePublic.tsx", [
        index("routes/competition/CompetitionListPublic.tsx"),
        route(":id_competition", "routes/competition/CompetitionHomePublic.tsx", [
          index("routes/competition/CompetitionDetailsPublic.tsx"),
          route("bibs", "routes/bib/BibHomePublic.tsx", [
            index("routes/bib/BibListPublic.tsx"),
          ]),
        ]),
      ]),
    ]),
  ]),
  route("dancers", "routes/dancer/DancerHomePublic.tsx", [
    index("routes/dancer/DancerListPublic.tsx"),
    route(":id_dancer", "routes/dancer/DancerPagePublic.tsx"),
  ]),
] satisfies RouteConfig;
