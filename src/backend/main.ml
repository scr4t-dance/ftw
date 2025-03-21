
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Helper functions *)
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

(* Main entrypoint *)
(* ************************************************************************* *)

let () =
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
