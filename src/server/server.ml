
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw.backend"

(* Static assets *)
(* ************************************************************************* *)

(* [lookup_file name dirs] finds the first file called [filename] in the list
   of firectories of the dune sites for assets *)
let find_sites_dir filename =
  List.find_map
    (fun dir ->
      let filename' = Filename.concat dir filename in
      if Sys.file_exists filename' then Some dir else None)
    Sites.Sites.assets

let loader _root path req =
  Logs.debug ~src (fun m -> m "Loading static request for '%s'" path);
  match path with
  | "" -> assert false (* should have been redirected before this point *)
  | _ ->
    match find_sites_dir path with
    | None ->
      Logs.debug ~src (fun m -> m "Path not found, returning 404");
      Dream.empty `Not_Found
    | Some dir ->
      Dream.from_filesystem dir path req


(* Main Server *)
(* ************************************************************************* *)

let delay s callback req =
  if s > 0 then Unix.sleep s;
  callback req

let server (options : Options.server) =
  (* Setup the dream server and run it *)
  Dream.run
    ~interface:"0.0.0.0"
    ~port:options.server_port
    ~tls:false
  @@ Dream.logger
  (* dream secret, see script in tests/script/dream_secret.ml *)
  @@ Dream.set_secret "NWRSF-Qa569MqaIzIAJCBRgzjUE8SSS2FE10env3EiQ"
    ~old_secrets:[]
  @@ Dream.cookie_sessions
  @@ State.init
    ~main_path:options.main_db_path
    ~user_path:options.user_db_path
    ~init:(not options.db_no_init)
  @@ User.init
  @@ Dream.router [

    (* Pages *)
    Dream_html.get Paths.Page.index Index.page;
    Dream_html.get Paths.Page.events Events.page;
    Dream_html.get Paths.Page.login Login.page;
    Dream_html.get Paths.Page.dancers Dancers.page;
    Dream_html.get Paths.Page.dancer Dancer.page;
    Dream_html.get Paths.Page.event Event.page;
    Dream_html.get Paths.Page.event_create Event.create_page;
    Dream_html.get Paths.Page.event_distrib Event.distrib;
    Dream_html.get Paths.Page.event_bibs Bibs.ev_page;
    Dream_html.get Paths.Page.comp Competition.page;
    Dream_html.get Paths.Page.comp_bibs Bibs.comp_page;
    Dream_html.get Paths.Page.phase Phase.page;
    Dream_html.get Paths.Page.judge_artefacts Artefacts.for_one_judge;

    (* API routes *)
    Dream.scope "/"
      [Dream.origin_referrer_check; delay options.api_delay] [

        Dream_html.get Paths.Htmx.events Events.api;
        Dream_html.get Paths.Htmx.comp_view Competition.htmx_view;
        Dream_html.get Paths.Htmx.phase_view Phase.htmx_view;
        Dream_html.post Paths.Htmx.login Login.post;
        Dream_html.get Paths.Htmx.logout Login.logout;
        Dream_html.post Paths.Htmx.set_passwd Dancer.htmx_set_passwd;
        Dream_html.get Paths.Htmx.event_reg Event.admin_event_reg;
        Dream_html.get Paths.Htmx.event_start Event.admin_event_start;
        Dream_html.post Paths.Htmx.distrib_add Event.distrib_add;
        Dream_html.post Paths.Htmx.distrib_delete Event.distrib_delete;
        Dream_html.get Paths.Htmx.comp_distrib Competition.htmx_distrib;
        Dream_html.get Paths.Htmx.comp_start Competition.htmx_start;
        Dream_html.post Paths.Htmx.phase_regen Phase.heat_regen_htmx;
        Dream_html.get Paths.Htmx.phase_start Phase.phase_start_htmx;
        Dream_html.get Paths.Htmx.phase_scoring Phase.phase_score_htmx;
        Dream_html.get Paths.Htmx.artefacts_view Artefacts.htmx_view;
        Dream_html.get Paths.Htmx.phase_finish Phase.phase_finish_htmx;

        Dream_html.post Paths.Post.dancers Dancers.post;
        Dream_html.post Paths.Post.event_create Event.create_post;
        Dream_html.post Paths.Post.event_distrib Event.distrib_api;
        Dream_html.post Paths.Htmx.distrib_dancer_add Event.distrib_dancer_add;
        Dream_html.post Paths.Post.artefacts Artefacts.post_artefacts;
        Dream_html.post Paths.Htmx.phase_pairing Phase.heat_pair_htmx;
    ];

    (* Default routes *)
    Dream.get "/" (fun req -> Dream_html.(redirect req (path_attr HTML.href Paths.Page.index)));
    Dream.get "/**" (Dream.static ~loader "");
  ]
