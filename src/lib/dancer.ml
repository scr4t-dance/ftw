
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Dancer

(* Serialization *)
(* ************************************************************************* *)

let to_toml d =
  []
  |> Misc.Toml.add "id" Id.to_toml (id d)
  |> Misc.Toml.add "last_name" Otoml.string (last_name d)
  |> Misc.Toml.add "first_name" Otoml.string (first_name d)
  |> Misc.Toml.add_opt "dob" Date.to_toml (birthday d)
  |> Misc.Toml.add_opt "email" Otoml.string (email d)
  |> Otoml.inline_table

let of_toml t =
  let id = Otoml.find t Id.of_toml ["id"] in
  let last_name = Otoml.find t Otoml.get_string ["last_name"] in
  let first_name = Otoml.find t Otoml.get_string ["first_name"] in
  let birthday = Otoml.find_opt t Date.of_toml ["dob"] in
  let email = Otoml.find_opt t Otoml.get_string ["email"] in
  let as_leader : Divisions.t = None in
  let as_follower : Divisions.t = None in
  Private.mk ~id ~birthday ~last_name ~first_name ~email ~as_leader ~as_follower


(* DB interaction *)
(* ************************************************************************* *)

let db = State.Main

let () =
  State.add_init ~name:"dancer" (fun st ->
      State.exec ~st ~db {|
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
       Private.mk ~id ~birthday ~last_name ~first_name ~email ~as_leader ~as_follower)

let get ~st id =
  try
    State.query_one_where ~st ~db ~p:Id.p ~conv
      {| SELECT * FROM dancers WHERE id = ? |} id
  with Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND ->
    raise Not_found

let for_all ~st ~f =
  State.query_all ~st ~db ~f ~conv
    {| SELECT * FROM dancers ORDER BY id |}

let list ~st =
  State.query_list ~st ~db ~conv
    {| SELECT * FROM dancers |}

let add ~st
    ~first_name ~last_name
    ?birthday ?email ~as_leader ~as_follower () =
  let email = Option.value ~default:"" email in
  let dob = Option.fold ~none:"" ~some:Date.to_string birthday in
  Logs.debug (fun k->
      k "@[<hv 2>Adding dancer with@ first: %s / last: %s@ birthday: %s / email : %s@ \
         leader: %a / follower: %a@]"
        first_name last_name dob email
        Divisions.print as_leader Divisions.print as_follower);
  State.insert ~st ~db ~ty:Db.Ty.[ text; text; text; text; int; int ]
    {| INSERT INTO dancers
        (birthday,last_name,first_name,email,as_leader,as_follower)
        VALUES (?,?,?,?,?,?) |}
    dob last_name first_name email
    (Divisions.to_int as_leader) (Divisions.to_int as_follower);
  (* TODO: try and get the id of the new competition from the insert statement above,
     rather than using a new query *)
  State.query_one_where ~st ~db ~p:Db.Ty.[ text; text; text; text; int; int ] ~conv
    {| SELECT * FROM dancers WHERE birthday = ? AND last_name = ? AND first_name = ?
                                AND email = ? AND as_leader = ? AND as_follower = ? |}
    dob last_name first_name email (Divisions.to_int as_leader) (Divisions.to_int as_follower)

let update ~st ~id_dancer ?birthday ~first_name ~last_name ?email ~as_leader ~as_follower () =
  let email = Option.value ~default:"" email in
  let dob = Option.fold ~none:"" ~some:Date.to_string birthday in
  Logs.debug (fun k->
      k "@[<hv 2>Updating dancer with@ first: %s / last: %s@ birthday: %s / email : %s@ \
         leader: %a / follower: %a@]"
        first_name last_name dob email
        Divisions.print as_leader Divisions.print as_follower);
  State.insert ~st ~db ~ty:Db.Ty.[ text; text; text; text; int; int; int ]
    {| UPDATE dancers SET birthday = ?,
                          last_name = ?, first_name = ?,
                          email = ?, as_leader = ?, as_follower = ?
                      WHERE id = ? |}
    dob last_name first_name email
    (Divisions.to_int as_leader) (Divisions.to_int as_follower)
    id_dancer

let update_divisions ~st ~dancer ~role ~divs =
  match (role : Role.t) with
  | Leader ->
    State.insert ~st ~db ~ty:Db.Ty.[int; int]
      {| UPDATE dancers SET as_leader = ? WHERE id = ? |}
      (Divisions.to_int divs) dancer
  | Follower ->
    State.insert ~st ~db ~ty:Db.Ty.[int; int]
      {| UPDATE dancers SET as_follower = ? WHERE id = ? |}
      (Divisions.to_int divs) dancer

(* Private functions *)
(* ************************************************************************* *)

module Private = struct

  include Ftw_core.Dancer.Private

  let import ~st ~id:dancer_id
      ~first_name ~last_name
      ?birthday ?email ~as_leader ~as_follower () =
    let email = Option.value ~default:"" email in
    let dob = Option.fold ~none:"" ~some:Date.to_string birthday in
    Logs.debug (fun k->
        k "@[<hv 2>Importing dancer with@ id: %a /@ \
           first: %s / last: %s@ \
           birthday: %s / email : %s@ \
           leader: %a / follower: %a@]"
          Id.print dancer_id first_name last_name dob email
          Divisions.print as_leader Divisions.print as_follower);
    State.insert ~st ~db ~ty:Db.Ty.[ int; text; text; text; text; int; int ]
      {| INSERT INTO dancers
        (id, birthday,last_name,first_name,email,as_leader,as_follower)
        VALUES (?, ?,?,?,?,?,?) |}
      dancer_id dob last_name first_name email
      (Divisions.to_int as_leader) (Divisions.to_int as_follower)


end

(* Indexing *)
(* ************************************************************************* *)

module Index = struct

  let src = Logs.Src.create "ftw.index"

  type dancer = t
  type t = dancer Str.Index.t Str.Index.t

  type res =
    | Found of dancer
    | Not_found of { suggestions : dancer list; }

  let empty = Str.Index.empty

  let prepare_name name =
    let l = String.split_on_char ' ' (String.trim name) in
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
    let first_name = prepare_name (first_name dancer) in
    let last_name = prepare_name (last_name dancer) in
    Str.Index.update index last_name ~f:(fun o ->
        let first_name_index = Option.value ~default:Str.Index.empty o in
        Str.Index.add first_name_index first_name dancer)

  let mk ~st =
    Logs.debug ~src (fun k->k "Creating dancer Index...");
    let i = ref Str.Index.empty in
    for_all ~st ~f:(fun dancer -> i := add dancer !i);
    Logs.debug ~src (fun k->k "Finished Index creation");
    !i

  let same_names ~first_name:first ~last_name:last = fun d ->
    String.equal (first_name d) first &&
    String.equal (last_name d) last

  let find_aux ?(limit=3) (index: t) ~first_name ~last_name =
    let s = Str.Index.find ~limit index last_name in
    let s = Seq.flat_map (fun idx -> Str.Index.find ~limit idx first_name) s in
    match s () with
    | Nil ->
      Not_found { suggestions = []; }
    | Cons _ ->
      begin match Seq.find (same_names ~first_name ~last_name) s with
        | Some d -> Found d
        | None -> Not_found { suggestions = List.of_seq s; }
      end

  let find ?limit index ~first_name ~last_name =
    let first_name = prepare_name first_name in
    let last_name = prepare_name last_name in
    Logs.debug ~src (fun k->k "Index query: %s / %s" last_name first_name);
    let t = Unix.gettimeofday () in
    let res = find_aux ?limit index ~first_name ~last_name in
    let t' = Unix.gettimeofday () in
    Logs.debug ~src (fun k->k "Dancer query solved in %.4fs" (t' -. t));
    res

end

