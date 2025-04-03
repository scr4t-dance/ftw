
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Main Server *)
(* ************************************************************************* *)

let loader _root path _request =
  match Static.read path with
    | None ->
      (* if the path is not found in the frontend, automatically redirect to `index.html` *)
      begin match Static.read "index.html" with
          | None -> assert false (* let's assume the frontend will always have an `index.html` *)
          | Some asset -> Dream.html asset
        end
    | Some asset -> Dream.respond asset

let server (options : Options.server) =
  (* Defaul routes to serve the clients files (pages, scripts and css) *)
  let default_routes = [
    Dream.get "/" (loader "" "");
    Dream.get "/**" (Dream.static ~loader "");
  ] in
  (* Setup the router with the base information for openapi *)
  let router =
    Router.empty
    |> Types.schemas
    |> Router.title "FTW"
    |> Router.version "1.0.1"
    |> Router.description "Api for the FTW dance competition scoring software"
    |> Router.license (
      Spec.make_license_object () ~name:"GPL 3.0"
        ~url:"https://www.gnu.org/licenses/gpl-3.0.en.html")
  in
  (* Add the routes for api endpoints *)
  let router =
    router
    |> Event.routes
    |> Competition.routes
  in
  (* Define CORS middleware manually *)
  let cors_middleware handler request =
    match Dream.method_ request with
    | `OPTIONS ->
      Dream.respond ~headers:[
        ("Access-Control-Allow-Origin", "*");
        ("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        ("Access-Control-Allow-Headers", "Content-Type, Authorization");
      ] ~status:`No_Content ""
    | _ ->
      let%lwt response = handler request in
      Dream.add_header response "Access-Control-Allow-Origin" "*";
      Dream.add_header response "Access-Control-Allow-Headers" "Content-Type, Authorization";
      Lwt.return response
  in
  (* Setup the dream server and run it *)
  Dream.run
    ~interface:"0.0.0.0"
    ~port:options.server_port
    ~tls:false
  @@ Dream.logger
  @@ cors_middleware
  @@ Dream.memory_sessions
  @@ State.init ~path:options.db_path
  @@ Router.build ~default_routes router

(* Event Import *)
(* ************************************************************************* *)

let import (options : Options.import) =
  Ftw.State.atomically (Ftw.State.mk options.db_path)
    ~f:(fun st ->
        match Ftw.Import.from_file st options.ev_path with
        | Ok () -> ()
        | Error msg ->
          Logs.err (fun k->k "Import failed: %s" msg);
          exit 1
      )

(* Event Export *)
(* ************************************************************************* *)

let export (options : Options.export) =
  Ftw.State.atomically (Ftw.State.mk options.db_path)
    ~f:(fun st ->
        match Ftw.Export.to_file ~st options.out_path options.ev_id with
        | Ok _ -> ()
        | Error () -> exit 1
      )

(* Main entrypoint *)
(* ************************************************************************* *)

let () =
  (* Parse CLI options *)
  let info = Cmdliner.Cmd.info ~version:"dev" "ftw" in
  let cmd =
    let open Cmdliner in
    Cmd.group ~default:Options.server info [
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
  | Ok `Ok Options.Import options -> import options
  | Ok `Ok Options.Export options -> export options

