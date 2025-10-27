
(* This file is free software, part of fourever. See file "LICENSE" for more information *)

open Cmdliner

(* Types *)
(* ************************************************************************* *)

type server = {
  db_path : string;
  db_no_init : bool;
  server_port : int;
}

type openapi = {
  file : string;
}

type init = {
  db_path : string;
  dancer_file : string option;
}

type import = {
  db_path : string;
  db_no_init : bool;
  ev_path : string;
}

type export = {
  db_path : string;
  db_no_init : bool;
  out_path : string;
  ev_id : int;
  dancer_export : Ftw.Export.dancer_export;
}

type t =
  | Server of server
  | Openapi of openapi
  | Init of init
  | Import of import
  | Export of export

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

let db_path =
  let doc = "Path to the sqlite db to use" in
  Arg.(required & opt (some string) None & info ["db"] ~doc)

let db_no_init =
  let doc = "Disable db initialisation (useful when the db is read-only)" in
  Arg.(value & flag & info ["no-init"] ~doc)

let dancer_list =
  let doc = "Whether to use stable (i.e. only use dancer ids) or not (and also
             emit and use bib numbers" in
  Arg.(value & opt (some file) None & info ["dancer-list"] ~doc)


(* Helper functions *)
(* ************************************************************************* *)

let dancer_export dancer_list : Ftw.Export.dancer_export =
  match dancer_list with
  | None -> Internal
  | Some dancer_file -> External { dancer_file }


(* Server options *)
(* ************************************************************************* *)

let server =
  let open Term.Syntax in
  let+ bt
  and+ logs_level
  and+ logs_style
  and+ db_path
  and+ db_no_init
  and+ server_port =
    let doc = "Port to listen on" in
    Arg.(value & opt int 8080 & info ["p"; "port"] ~doc)
  in
  setup_bt bt;
  setup_log logs_style logs_level;
  Server { db_path; db_no_init; server_port; }

(* Openapi options *)
(* ************************************************************************* *)

let openapi =
  let open Term.Syntax in
  let+ bt
  and+ logs_level
  and+ logs_style
  and+ file =
    let doc = "Output file for the openapi doc" in
    Arg.(required & pos 0 (some string) None & info [] ~doc ~docv:"FILE")
  in
  setup_bt bt;
  setup_log logs_style logs_level;
  Openapi { file; }

(* Init option *)
(* ************************************************************************* *)

let init =
  let open Term.Syntax in
  let+ bt
  and+ db_path
  and+ logs_level
  and+ logs_style
  and+ dancer_list
  in
  setup_bt bt;
  setup_log logs_style logs_level;
  Init { db_path; dancer_file = dancer_list; }


(* Import options *)
(* ************************************************************************* *)

let import =
  let open Term.Syntax in
  let+ bt
  and+ db_path
  and+ db_no_init
  and+ logs_level
  and+ logs_style
  and+ ev_path =
    let doc = "Path of the serialized event(s) to import. Can be either
               a path to a file to import, or a path to a directory from
               which all events (i.e. files ending in .toml) will be
               imported." in
    Arg.(required & pos 0 (some file) None & info [] ~doc ~docv:"FILE")
  in
  setup_bt bt;
  setup_log logs_style logs_level;
  Import { db_path; db_no_init; ev_path; }

(* Export options *)
(* ************************************************************************* *)

let export =
  let open Term.Syntax in
  let+ bt
  and+ db_path
  and+ db_no_init
  and+ logs_level
  and+ logs_style
  and+ out_path =
    let doc = "Path of the file to generate with the serialized event info" in
    Arg.(required & pos 0 (some string) None & info [] ~doc ~docv:"FILE")
  and+ ev_id =
    let doc = "Id of the event to export" in
    Arg.(required & opt (some int) None & info ["id"] ~doc)
  and+ dancer_list
  in
  setup_bt bt;
  setup_log logs_style logs_level;
  let dancer_export = dancer_export dancer_list in
  Export { db_path; db_no_init; out_path; ev_id; dancer_export; }

