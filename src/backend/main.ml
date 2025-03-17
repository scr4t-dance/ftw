
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Helper functions *)
(* ************************************************************************* *)

let index_loader _root _path _request =
  match Static.read "index.html" with
  | Some index -> Dream.html index
  | None -> Dream.respond ~status:`Not_Found "Index file not found"

let static_loader _root path _request =
  match Static.read path with
  | None -> Dream.empty `Not_Found
  | Some asset -> Dream.respond asset

(* Main entrypoint *)
(* ************************************************************************* *)

let () =
  Dream.initialize_log ~level:`Debug ();
  (* Parse CLI options *)
  let info = Cmdliner.Cmd.info ~version:"dev" "fourever" in
  let cmd = Cmdliner.Cmd.v info Options.t in
  let options =
    match Cmdliner.Cmd.eval_value cmd with
    | Ok `Ok options -> options
    | Ok (`Help | `Version) -> exit 0
    | Error `Parse -> exit Cmdliner.Cmd.Exit.cli_error
    | Error (`Term | `Exn) -> exit Cmdliner.Cmd.Exit.internal_error
  in
  (* Defaul routes to serve the clients files (pages, scripts and css) *)
  let default_routes = [
    Dream.get "/" (index_loader "" "");
    Dream.get "/static/**" (Dream.static ~loader:static_loader "");
    Dream.get "/**" (Dream.static ~loader:index_loader "");
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
