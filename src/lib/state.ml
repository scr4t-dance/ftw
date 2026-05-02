
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw.state"

(* Type definition *)
(* ************************************************************************* *)

type t = {
  main : Db.t;
  users : Db.t;
}

type db =
  | Main
  | Users

(* DB wrappers *)
(* ************************************************************************* *)

let sqldb ~db { main; users } =
  match db with
  | Main -> main
  | Users -> users

let atomically { main; users; } ~f =
  Db.atomically main (fun main ->
    Db.atomically users (fun users ->
          f { main; users; }
        )
    )

let exec ~st ~db sql =
  Db.exec ~db:(sqldb ~db st) sql

let insert ~st ~db ~ty sql =
  Db.insert ~db:(sqldb ~db st) ~ty sql

let query_all ~st ~db ~f ~conv sql =
  Db.query_all ~db:(sqldb ~db st) ~f ~conv sql

let query_list ~st ~db ~conv sql =
  Db.query_list ~db:(sqldb ~db st) ~conv sql

let query_all_where ~st ~db ~f ~p ~conv sql =
  Db.query_all_where ~db:(sqldb ~db st) ~f ~p ~conv sql

let query_list_where ~st ~db ~p ~conv sql =
  Db.query_list_where ~db:(sqldb ~db st) ~p ~conv sql

let query_one_where ~st ~db ~p ~conv sql =
  Db.query_one_where ~db:(sqldb ~db st) ~p ~conv sql


(* DB creation & initialization *)
(* ************************************************************************* *)

let initializers = ref []

let add_init ~name f =
  initializers := (name, f) :: !initializers

let mk ~init ~user_path ~main_path =
  let main = Sqlite3.db_open main_path in
  let users = Sqlite3.db_open user_path in
  let st = { main; users } in
  (* Enable foreign keys so that the "REFERENCES" uses in tables are
     actually enforced and checked. *)
  exec ~db:Main ~st {| PRAGMA foreign_keys = ON |};
  exec ~db:Users ~st {| PRAGMA foreign_keys = ON |};
  if init then begin
    Logs.debug ~src (fun k->k "Starting state & DB initialization");
    List.iter (fun (name, f)->
        try f st
        with
        | Sqlite3.Error msg as exn ->
          let bt = Printexc.get_backtrace () in
          Logs.err ~src (fun k ->
              k "SQLite error during initialization for %s: %s\nBacktrace:\n%s"
                name msg bt);
          raise exn
        | exn ->
          let bt = Printexc.get_backtrace () in
          Logs.err ~src (fun k ->
              k "Failed initialization for %s: %s\nBacktrace:\n%s"
                name (Printexc.to_string exn) bt);
          raise exn
      ) (List.rev !initializers);
    Logs.debug ~src (fun k->k "Finished initialization of state & DB")
  end;
  st

(* Helper for intializing tables that are mainly here so that the DB can
   be (more or less) self-describing, or at least a bit more readable
   without context. *)
let add_init_descr_table ~db ~table_name ~to_int ~to_descr ~values () =
  let aux st =
    (* create table *)
    exec ~st ~db (Format.asprintf {|
      CREATE TABLE IF NOT EXISTS %s (
        id INTEGER PRIMARY KEY,
        name TEXT UNIQUE)
      |} table_name);
    (* Add all values *)
    List.iter (fun value ->
        let name = to_descr value in
        let open Db.Ty in
        insert ~st ~db ~ty:[ int; text; ]
          (Format.asprintf
             {| INSERT OR IGNORE INTO %s (id, name) VALUES (?,?) |} table_name)
          (to_int value) name
      ) values
  in
  add_init ~name:table_name aux


