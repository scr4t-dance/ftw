
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Bib


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
  dancer_id : Dancer.id;
  _competition_id : Competition.id;
  bib : t;
  role : Role.t;
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
    when Id.equal leader_bib follow_bib ->
    Some (r, leader_bib, Target.Any (Couple { leader; follower; }))
  (* Single case *)
  | { dancer_id = target; role; bib; _ } :: r ->
    Some (r, bib, Target.Any (Single { target; role; }))
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
  match (target : _ Target.any) with
  | Any Single { target = dancer; role; } ->
    begin match
      State.query_one_where ~st ~db ~conv:Id.conv ~p:Db.Ty.[int; int; int]
      {| SELECT bib FROM bibs WHERE competition_id = ? AND dancer_id = ? AND role = ? |}
      (Competition.id comp) (Dancer.id dancer) (Role.to_int role)
    with
      | bib ->
        begin match get ~st ~competition:(Competition.id comp) ~bib with
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
      (Competition.id comp)
      (Dancer.id leader) (Role.to_int Leader)
      (Dancer.id follower) (Role.to_int Follower)
    with
      | [b; b'] when b = b' ->
        begin match get ~st ~competition:(Competition.id comp) ~bib:b with
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

module TMap = Stdlib.Map.Make(Target.Ord(Id))

let get_map ~st ~comp =
  let l = get_all ~st ~competition:(Ftw_core.Competition.id comp) in
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
  match (target : Id.t Target.any) with
  | Any Single { target; role; } ->
    insert_row ~st ~bib ~competition ~dancer:target ~role
  | Any Couple { leader; follower; } ->
    insert_row ~st ~bib ~competition ~dancer:leader ~role:Leader;
    insert_row ~st ~bib ~competition ~dancer:follower ~role:Follower
  | Any Trouple _ ->
    failwith "TODO"

let update ~st ~competition ~old_bib ~new_bib =
  let existing_target_result = get ~st ~competition ~bib:old_bib in
  let new_target = get ~st ~competition ~bib:new_bib in
  begin match existing_target_result, new_target with
    | Some _, None ->
      let open Sqlite3_utils.Ty in
      State.insert ~st ~db ~ty:[int;int;int]
        {| UPDATE bibs
        SET bib = ?
        WHERE 0=0
        AND competition_id = ?
        AND bib = ?
        |}
        new_bib competition old_bib
    | None, _ -> raise Not_found
    | _, Some _ -> raise (Failure "new bib already in use")
  end

let delete ~st ~competition ~bib =
  let existing_target = get ~st ~competition ~bib in
  begin match existing_target with
    | Some any ->
      Logs.warn (fun k->k "Delete target: %a / %d" (Target.print Id.print) any bib)
    | None ->
      (* TODO: error message ? *)
      raise Not_found
  end;
  let open Sqlite3_utils.Ty in
  State.insert ~st ~db ~ty:[int;int]
    {| DELETE FROM bibs WHERE competition_id = ? AND bib = ? |}
    competition bib
