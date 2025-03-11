
(* This file is free software, part of fourever. See file "LICENSE" for more information *)

open Cmdliner

(* Options record *)
(* ************************************************************************* *)

type t = {
  db_path : string;
  server_port : int;
  static_path : string;
}

let mk db_path server_port static_path =
  { db_path; server_port; static_path; }

(* Cmdliner term *)
(* ************************************************************************* *)

let t =
  let db_path =
    let doc = "Path to the sqlite db to use" in
    Arg.(required & opt (some string) None & info ["db"] ~doc)
  in
  let port =
    let doc = "Port to listen on" in
    Arg.(value & opt int 8080 & info ["p"; "port"] ~doc)
  in
  let static_path =
    let doc = "Static file path to serve" in
    Arg.(value & opt string "src/backend/static" & info ["s"; "static"] ~doc)
  in
  Term.(const mk $ db_path $ port $ static_path)

