
(* This file is free software, part of fourever. See file "LICENSE" for more information *)

open Cmdliner

(* Types *)
(* ************************************************************************* *)

type server = {
  db_path : string;
  server_port : int;
}

type import = {
  db_path : string;
  ev_path : string;
}

type export = {
  db_path : string;
  out_path : string;
  ev_id : int;
}

type t =
  | Server of server
  | Import of import
  | Export of export

(* Logs & debugging *)
(* ************************************************************************* *)

let logs_level = Logs_cli.level ()

let logs_style = Fmt_cli.style_renderer ()

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level ~all:true level;
  Logs.set_reporter (Logs_fmt.reporter ())

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


(* Server options *)
(* ************************************************************************* *)

let server =
  let open Term.Syntax in
  let+ bt
  and+ db_path
  and+ server_port =
    let doc = "Port to listen on" in
    Arg.(value & opt int 8080 & info ["p"; "port"] ~doc)
  in
  setup_bt bt;
  Server { db_path; server_port; }


(* Import options *)
(* ************************************************************************* *)

let import =
  let open Term.Syntax in
  let+ bt
  and+ db_path
  and+ logs_level
  and+ logs_style
  and+ ev_path =
    let doc = "Path of the serialized event to import" in
    Arg.(required & pos 0 (some non_dir_file) None & info [] ~doc ~docv:"FILE")
  in
  setup_bt bt;
  setup_log logs_style logs_level;
  Import { db_path; ev_path; }


(* Import options *)
(* ************************************************************************* *)

let export =
  let open Term.Syntax in
  let+ bt
  and+ db_path
  and+ logs_level
  and+ logs_style
  and+ out_path =
    let doc = "Path of the file to generate with the serialized event info" in
    Arg.(required & pos 0 (some string) None & info [] ~doc ~docv:"FILE")
  and+ ev_id =
    let doc = "Id of the event to export" in
    Arg.(required & opt (some int) None & info ["id"] ~doc)
  in
  setup_bt bt;
  setup_log logs_style logs_level;
  Export { db_path; out_path; ev_id; }


