
let loader _root path _request =
  match Static.read path with
  | None -> Dream.empty `Not_Found
  | Some asset -> Dream.respond asset

let () =
  let info = Cmdliner.Cmd.info ~version:"dev" "fourever" in
  let cmd = Cmdliner.Cmd.v info Options.t in
  let options =
    match Cmdliner.Cmd.eval_value cmd with
    | Ok `Ok options -> options
    | Ok (`Help | `Version) -> exit 0
    | Error `Parse -> exit Cmdliner.Cmd.Exit.cli_error
    | Error (`Term | `Exn) -> exit Cmdliner.Cmd.Exit.internal_error
  in
  Dream.run
    ~interface:"0.0.0.0"
    ~port:options.server_port
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ State.init ~path:options.db_path
  @@ Dream.router [
    (* static content *)
    Dream.get "/static/**" (Dream.static ~loader "")
  ]

