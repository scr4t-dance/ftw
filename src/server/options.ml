
(* This file is free software, part of fourever. See file "LICENSE" for more information *)

open Cmdliner

(* Types *)
(* ************************************************************************* *)

type server = {
  main_db_path : string;
  user_db_path : string;
  db_no_init : bool;
  server_port : int;
  api_delay : int;
}

type init = {
  main_db_path : string;
  user_db_path : string;
  dancer_file : string option;
}

type import = {
  main_db_path : string;
  user_db_path : string;
  db_no_init : bool;
  ev_path : string;
}

type export = {
  main_db_path : string;
  user_db_path : string;
  db_no_init : bool;
  out_path : string;
  ev_id : int;
  dancer_export : Ftw_db.Export.dancer_export;
}

type set_admin = {
  main_db_path : string;
  user_db_path : string;
  db_no_init : bool;
  username : string;
  pwd : string;
  email : string;
  dancer_id : int;
}

type t =
  | Server of server
  | Init of init
  | Import of import
  | Export of export
  | Set_admin of set_admin

(* Logs & debugging *)
(* ************************************************************************* *)

let logs_level = Logs_cli.level ()

let logs_style = Fmt_cli.style_renderer ()

let set_dream_logs level =
  let level : Dream.log_level option =
    Option.map (fun l ->
        match (l : Logs.level) with
        | Logs.Error -> `Error
        | Logs.Warning -> `Warning
        | Logs.Info -> `Info
        | Logs.Debug -> `Debug
        | Logs.App -> `Info
      ) level
  in
  Dream.initialize_log () ?level

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  set_dream_logs level;
  Logs.set_level ~all:true level;
  ()

let bt =
  let doc = "Enable backtraces" in
  Arg.(value & flag & info ["b"] ~doc)

let setup_bt bt =
  if bt then begin
    Sys.catch_break true;
    Printexc.record_backtrace true
  end;
  ()

(* Common args *)
(* ************************************************************************* *)

let main_db_path =
  let doc = "Path to the main sqlite db to use" in
  Arg.(required & opt (some string) None & info ["db"] ~doc)

let user_db_path =
  let doc = "Path to the user sqlite db to use" in
  Arg.(required & opt (some string) (Some ":memory:") & info ["user-db"] ~doc)

let db_no_init =
  let doc = "Disable db initialisation (useful when the db is read-only)" in
  Arg.(value & flag & info ["no-init"] ~doc)


(* Server options *)
(* ************************************************************************* *)

let server =
  let open Term.Syntax in
  let+ bt
  and+ logs_level
  and+ logs_style
  and+ main_db_path
  and+ user_db_path
  and+ db_no_init
  and+ server_port =
    let doc = "Port to listen on" in
    Arg.(value & opt int 8080 & info ["p"; "port"] ~doc)
  and+ api_delay =
    let doc = "Delay for all API queries. Mainly for testing purposes" in
    Arg.(value & opt int 0 & info ["delay"] ~doc)
  in
  setup_bt bt;
  setup_log logs_style logs_level;
  Server { main_db_path; user_db_path; db_no_init; server_port; api_delay; }

