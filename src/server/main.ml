
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw.backend"

(* Initialization *)
(* ************************************************************************* *)

(* [lookup_file name dirs] finds the first file called [filename] in the list
   of firectories of the dune sites for assets *)
let find_sites_dir filename =
  List.find_map
    (fun dir ->
      let filename' = Filename.concat dir filename in
      if Sys.file_exists filename' then Some dir else None)
    Sites.Sites.assets

(* Main Server *)
(* ************************************************************************* *)

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

let delay s callback req =
  if s > 0 then Unix.sleep s;
  callback req

let%path index = "/index.html"
let%path events_page = "/events"
let%path events_api = "/events"


let server (options : Options.server) =
  (* Default routes to serve the clients files (pages, scripts and css) *)
  let default_routes = [
    Dream.get "/" (fun req -> Dream.redirect req "/index.html");
    Dream.get "/**" (Dream.static ~loader "");
  ] in
  (* Setup the dream server and run it *)
  Dream.run
    ~interface:"0.0.0.0"
    ~port:options.server_port
    ~tls:false
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ State.init
    ~main_path:options.main_db_path
    ~user_path:options.user_db_path
    ~init:(not options.db_no_init)
  @@ Dream.router (
    Dream.scope "/api"
      [Dream.origin_referrer_check; delay options.api_delay] [
        Dream_html.get events_api Page_event_list.api;
    ] ::
    Dream_html.get index Page_index.page ::
    Dream_html.get events_page Page_event_list.page ::
    default_routes
  )


(* DB init *)
(* ************************************************************************* *)

let init (options : Options.init) =
  let st =
    Ftw.State.mk ~init:true
      ~main_path:options.main_db_path
      ~user_path:options.user_db_path
  in
  Ftw.State.atomically ~st
    ~f:(fun st ->
        match options.dancer_file with
        | None ->
          Logs.warn ~src (fun k->k "No dancer list provided")
        | Some file ->
          Ftw.Import.import_dancers ~st file
      )

(* Event Import *)
(* ************************************************************************* *)

let import (options : Options.import) =
  let st =
    Ftw.State.mk ~init:(not options.db_no_init)
    ~main_path:options.main_db_path
    ~user_path:options.user_db_path
  in
  Ftw.State.atomically ~st
    ~f:(fun st ->
        match Ftw.Import.import_event ~st options.ev_path with
        | Ok _ev_ids -> ()
        | Error msg ->
          Logs.err ~src (fun k->k "Import failed: %s" msg);
          raise Exit
      )

(* Event Export *)
(* ************************************************************************* *)

let export (options : Options.export) =
  let st =
    Ftw.State.mk ~init:(not options.db_no_init)
      ~main_path:options.main_db_path
      ~user_path:options.user_db_path
  in
  Ftw.State.atomically ~st
    ~f:(fun st ->
        match Ftw.Export.export_event
                ~st options.out_path options.ev_id with
        | Ok _ -> ()
        | Error () -> raise Exit
      )

(* Main entrypoint *)
(* ************************************************************************* *)

let () =
  (* Parse CLI options *)
  let info = Cmdliner.Cmd.info ~version:"dev" "ftw" in
  let cmd =
    let open Cmdliner in
    Cmd.group ~default:Options.server info [
      Cmd.v (Cmd.info "init") Options.init;
      Cmd.v (Cmd.info "import") Options.import;
      Cmd.v (Cmd.info "export") Options.export;
    ]
  in
  match Cmdliner.Cmd.eval_value cmd with
  (* Errors *)
  | Error `Parse -> exit Cmdliner.Cmd.Exit.cli_error
  | Error (`Term | `Exn) -> exit Cmdliner.Cmd.Exit.internal_error
  (* Help / Version *)
  | Ok (`Help | `Version) -> exit 0
  (* Options parsed, run the code *)
  | Ok `Ok Options.Server options -> server options
  | Ok `Ok Options.Init options -> init options
  | Ok `Ok Options.Import options -> import options
  | Ok `Ok Options.Export options -> export options
