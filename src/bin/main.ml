
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw"

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
  Ftw.State.atomically ~st ~f:(fun st ->
    match Ftw.Export.export_event
            ~st options.out_path options.ev_id with
    | Ok _ -> ()
    | Error () -> raise Exit
  )

(* Set admin endpoint *)
(* ************************************************************************* *)

let set_admin (options: Options.set_admin) =
  let st =
    Ftw.State.mk ~init:(not options.db_no_init)
      ~main_path:options.main_db_path
      ~user_path:options.user_db_path
  in
  Ftw.State.atomically ~st ~f:(fun st ->
    let user =
      Ftw.User.create ~st
        ~username:options.username
        ~email:options.email
        ~pwd:options.pwd
        ~dancer_id:options.dancer_id
    in
    Ftw.Position.add ~st ~user Admin
  )


(* Strip endpoint *)
(* ************************************************************************* *)

let snapshot (options: Options.snapshot) =
  Ftw.Snapshot.make
    ~origin_db_path:options.origin_db_path
    ~target_db_path:options.target_db_path


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
      Cmd.v (Cmd.info "set-admin") Options.set_admin;
      Cmd.v (Cmd.info "snapshot") Options.snapshot;
    ]
  in
  match Cmdliner.Cmd.eval_value cmd with
  (* Errors *)
  | Error `Parse -> exit Cmdliner.Cmd.Exit.cli_error
  | Error (`Term | `Exn) -> exit Cmdliner.Cmd.Exit.internal_error
  (* Help / Version *)
  | Ok (`Help | `Version) -> exit 0
  (* Options parsed, run the code *)
  | Ok `Ok Options.Server options -> Ftw_server.Server.server options
  | Ok `Ok Options.Init options -> init options
  | Ok `Ok Options.Import options -> import options
  | Ok `Ok Options.Export options -> export options
  | Ok `Ok Options.Set_admin options -> set_admin options
  | Ok `Ok Options.Snapshot options -> snapshot options


