
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

open! Lib.Bib


(* DB interaction *)
(* ************************************************************************* *)

(** The primary key for bib table is bib,competition_id,role.
    It allows to work with either:
    - same bib for dancer as lead and follow
    - different bibs for leaders and followers
*)
let db = State.Main

let () =
  State.add_init ~name:"bib" (fun st ->
      State.exec ~st ~db {|
        CREATE TABLE IF NOT EXISTS bibs (
          dancer_id INTEGER REFERENCES dancers(id),
          competition_id INTEGER REFERENCES competitions(id),
          bib INTEGER NOT NULL,
          role INTEGER NOT NULL,

          PRIMARY KEY(bib,competition_id,role)
        )
      |})

type row = {
  dancer_id : Lib.Dancer.id;
  _competition_id : Lib.Competition.id;
  bib : Lib.Bib.t;
  role : Lib.Role.t;
}

let conv =
  Conv.mk Db.Ty.[int;int;int;int]
    (fun dancer_id _competition_id bib role ->
       let role = Role.of_int role in
       { dancer_id; _competition_id; bib; role; }
    )

let conv_one_bib = function
  (* Couple cases;
     the "ORDER BY" clause in the SQL query should ensure the order. *)
  | { dancer_id = leader; role = Leader; bib = leader_bib; _ } ::
    { dancer_id = follower; role = Follower; bib = follow_bib; _ } :: r
    when Lib.Id.equal leader_bib follow_bib ->
    Some (r, leader_bib, Lib.Target.Any (Couple { leader; follower; }))
  (* Single case *)
  | { dancer_id = target; role; bib; _ } :: r ->
    Some (r, bib, Lib.Target.Any (Single { target; role; }))
  (* Not in database *)
  | [] -> None

let rec conv_all_bibs = function
  | [] -> []
  | (_ :: _) as l ->
    begin match conv_one_bib l with
      | Some (r, bib, any) -> (bib, any) :: conv_all_bibs r
      | None -> assert false
    end

let get ~st ~competition ~bib =
  let rows =
    State.query_list_where ~st ~db ~conv ~p:Db.Ty.[int;int]
      {| SELECT * FROM bibs WHERE bib = ? AND competition_id = ? |}
      bib competition
  in
  match rows with
  | l ->
    begin match conv_one_bib l with
      | None -> None
      | Some ([], _, res) -> Some res
      | Some (_ :: _, _, _) ->
        (* corrupted database *)
        assert false
    end
  | exception Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND -> None

let find ~st ~comp target =
  match (target : _ Lib.Target.any) with
  | Any Single { target = dancer; role; } ->
    begin match
      State.query_one_where ~st ~db ~conv:Id.conv ~p:Db.Ty.[int; int; int]
      {| SELECT bib FROM bibs WHERE competition_id = ? AND dancer_id = ? AND role = ? |}
      (Lib.Competition.id comp) (Lib.Dancer.id dancer) (Role.to_int role)
    with
      | bib ->
        begin match get ~st ~competition:(Lib.Competition.id comp) ~bib with
          | Some target -> Some (bib, target)
          | None -> assert false
        end
      | exception Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND -> None
    end
  | Any Couple { leader; follower; } ->
    begin match
      State.query_list_where ~st ~db ~conv:Id.conv ~p:Db.Ty.[int; int; int; int; int]
      {| SELECT bib FROM bibs WHERE competition_id = ?
                                AND ((dancer_id = ? AND role = ?) OR
                                      (dancer_id = ? AND role = ?))|}
      (Lib.Competition.id comp)
      (Lib.Dancer.id leader) (Role.to_int Leader)
      (Lib.Dancer.id follower) (Role.to_int Follower)
    with
      | [b; b'] when b = b' ->
        begin match get ~st ~competition:(Lib.Competition.id comp) ~bib:b with
          | Some target -> Some (b, target)
          | None -> assert false
        end
      | _ -> None
      | exception Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND -> None
    end
  | Any Trouple _ -> assert false

let get_all ~st ~competition =
  let open Sqlite3_utils.Ty in
  match
    State.query_list_where ~st ~db ~conv ~p:[int]
      {| SELECT * FROM bibs WHERE competition_id = ? ORDER BY bib, role |}
      competition
  with
  | l -> conv_all_bibs l
  | exception Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND -> []

module TMap = Stdlib.Map.Make(Lib.Target.Ord(Lib.Id))

let get_map ~st ~comp =
  let l = get_all ~st ~competition:(Lib.Competition.id comp) in
  List.fold_left (fun acc (bib, target) -> TMap.add target bib acc) TMap.empty l

let insert_row ~st ~competition ~dancer ~role ~bib =
  State.insert ~st ~db ~ty:Db.Ty.[int;int;int;int]
    {| INSERT INTO bibs(dancer_id,competition_id,bib,role) VALUES (?,?,?,?) |}
    dancer competition bib (Role.to_int role)

let add ~st ~competition ~target ~bib =
  let existing_target = get ~st ~competition ~bib in
  begin match existing_target with
    | Some _ ->
      (* duplicate bib *)
      assert false
    | None -> ()
  end;
  match (target : Lib.Id.t Lib.Target.any) with
  | Any Single { target; role; } ->
    insert_row ~st ~bib ~competition ~dancer:target ~role
  | Any Couple { leader; follower; } ->
    insert_row ~st ~bib ~competition ~dancer:leader ~role:Leader;
    insert_row ~st ~bib ~competition ~dancer:follower ~role:Follower
  | Any Trouple _ ->
    failwith "TODO"

let delete ~st ~competition ~bib =
  let existing_target = get ~st ~competition ~bib in
  begin match existing_target with
    | Some any ->
      Logs.warn (fun k->k "Delete target: %a / %d" (Lib.Target.print Lib.Id.print) any bib)
    | None ->
      (* TODO: error message ? *)
      raise Not_found
  end;
  let open Sqlite3_utils.Ty in
  State.insert ~st ~db ~ty:[int;int]
    {| DELETE FROM bibs WHERE competition_id = ? AND bib = ? |}
    competition bib
