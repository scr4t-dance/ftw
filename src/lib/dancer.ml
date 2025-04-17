
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t

type t = {
  id : id;
  birthday : Date.t option;
  last_name : string;
  first_name : string;
  email : string option;
  as_leader : Divisions.t;
  as_follower : Divisions.t;
}

(* Accessors *)
(* ************************************************************************* *)

let id { id; _ } = id
let birthday { birthday; _ } = birthday
let last_name { last_name; _ } = last_name
let first_name { first_name; _ } = first_name
let as_leader { as_leader; _ } = as_leader
let as_follower { as_follower; _ } = as_follower
let email { email; _ } = email

let print_compact fmt t =
  Format.fprintf fmt "%s %s" t.first_name t.last_name

(* DB interaction *)
(* ************************************************************************* *)

let () =
  State.add_init ~name:"dancer" (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS dancers (
          id INTEGER PRIMARY KEY,
          birthday TEXT,
          last_name TEXT,
          first_name TEXT,
          email TEXT,
          as_leader INTEGER REFERENCES divisions_names(id),
          as_follower INTEGER REFERENCES divisions_names(id)
        )
      |})

let conv =
  Conv.mk
    Sqlite3_utils.Ty.[int; text; text; text; text; int; int]
    (fun id birthday last_name first_name email as_leader as_follower ->
       let birthday = if birthday = "" then None else Some (Date.of_string birthday) in
       let email = if email = "" then None else Some email in
       let as_leader = Divisions.of_int as_leader in
       let as_follower = Divisions.of_int as_follower in
       { id; birthday; last_name; first_name; email; as_leader; as_follower; })

let get ~st id =
  State.query_one_where ~p:Id.p ~conv ~st
    {| SELECT * FROM dancers WHERE id = ? |} id

let for_all ~st ~f =
  State.query_all ~f ~st ~conv
    {| SELECT * FROM dancers |}

let add ~st ?birthday ~first_name ~last_name ?email ~as_leader ~as_follower () =
  let open Sqlite3_utils.Ty in
  let email = Option.value ~default:"" email in
  let dob = Option.fold ~none:"" ~some:Date.to_string birthday in
  Logs.debug (fun k->
      k "@[<hv 2>Adding dancer with@ first: %s / last: %s@ birthday: %s / email : %s@ \
                 leader: %a / follower: %a@]"
        first_name last_name dob email
        Divisions.print as_leader Divisions.print as_follower);
  State.insert ~st ~ty:[ text; text; text; text; int; int ]
    {| INSERT INTO dancers
        (birthday,last_name,first_name,email,as_leader,as_follower) VALUES (?,?,?,?,?,?) |}
    dob last_name first_name email (Divisions.to_int as_leader) (Divisions.to_int as_follower);
  (* TODO: try and get the id of the new competition from the insert statement above,
     rather than using a new query *)
  State.query_one_where ~p:[ text; text; text; text; int; int ] ~conv ~st
    {| SELECT * FROM dancers WHERE birthday = ? AND last_name = ? AND first_name = ?
                                AND email = ? AND as_leader = ? AND as_follower = ? |}
    dob last_name first_name email (Divisions.to_int as_leader) (Divisions.to_int as_follower)


let update_divisions ~st ~dancer ~role ~divs =
  let open Sqlite3_utils.Ty in
  match (role : Role.t) with
  | Leader ->
    State.insert ~st ~ty:[int; int]
      {| UPDATE dancers SET as_leader = ? WHERE id = ? |}
      (Divisions.to_int divs) dancer
  | Follower ->
    State.insert ~st ~ty:[int; int]
      {| UPDATE dancers SET as_follower = ? WHERE id = ? |}
      (Divisions.to_int divs) dancer


(* Indexing *)
(* ************************************************************************* *)

module Index = struct

  let src = Logs.Src.create "ftw.dancer.index"

  type dancer = t
  type t = dancer Str.Index.t Str.Index.t

  type res =
    | Found of dancer
    | Not_found of { suggestions : dancer list; }

  let empty = Str.Index.empty

  let prepare_name name =
    let l = String.split_on_char ' ' name in
    let l =
      List.filter_map (fun s ->
          let s = String.trim s in
          let l' = String.split_on_char '-' s in
          let l' =
            List.filter_map (fun s ->
                let s = String.trim s in
                let s = String.capitalize_ascii s in
                if s = "" then None else Some s
              ) l'
          in
          let s = String.concat "-" l' in
          if s = "" then None else Some s
        ) l
    in
    String.concat " " l

  let add dancer index =
    let first_name = prepare_name dancer.first_name in
    let last_name = prepare_name dancer.last_name in
    Str.Index.update index last_name ~f:(fun o ->
        let first_name_index = Option.value ~default:Str.Index.empty o in
        Str.Index.add first_name_index first_name dancer)

  let mk ~st =
    Logs.debug ~src (fun k->k "Creating dancer Index...");
    let i = ref Str.Index.empty in
    for_all ~st ~f:(fun dancer -> i := add dancer !i);
    Logs.debug ~src (fun k->k "Finished Index creation");
    !i

  let find_aux (index : t) ~first_name ~last_name =
    let limit = 3 in
    let s = Str.Index.find ~limit index last_name in
    let s = Seq.flat_map (fun idx -> Str.Index.find ~limit idx first_name) s in
    match s () with
    | Nil ->
      Not_found { suggestions = []; }
    | Cons (d, s') ->
      if d.first_name = first_name && d.last_name = last_name then
        Found d
      else
        Not_found { suggestions = d :: List.of_seq s'; }

  let find index ~first_name ~last_name =
    let first_name = prepare_name first_name in
    let last_name = prepare_name last_name in
    Logs.debug ~src (fun k->k "Index query: %s / %s" last_name first_name);
    let t = Unix.gettimeofday () in
    let res = find_aux index ~first_name ~last_name in
    let t' = Unix.gettimeofday () in
    Logs.debug ~src (fun k->k "Dancer query solved in %.4fs" (t' -. t));
    res

end
