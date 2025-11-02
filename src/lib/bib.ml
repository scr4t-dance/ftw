
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t = Id.t

(* Usual functions *)
(* ************************************************************************* *)

let compare t t' = Id.compare t t'
let equal t t' = compare t t' = 0

module Aux = struct
  type nonrec t = t
  let compare = compare
end

module Set = Set.Make(Aux)
module Map = Map.Make(Aux)

(* DB interaction *)
(* ************************************************************************* *)

let () =
  State.add_init ~name:"bib" (fun st ->
      State.exec ~st {|
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
  competition_id : Competition.id;
  bib : t;
  role : Role.t;
}

let conv =
  Conv.mk Sqlite3_utils.Ty.[int;int;int;int]
    (fun dancer_id competition_id bib role ->
       let role = Role.of_int role in
       { dancer_id; competition_id; bib; role; }
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
  let open Sqlite3_utils.Ty in
  let rows =
    State.query_list_where ~st ~conv ~p:[int;int]
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

let get_all ~st ~competition =
  let open Sqlite3_utils.Ty in
  match
    State.query_list_where ~st ~conv ~p:[int]
      {| SELECT * FROM bibs WHERE competition_id = ? ORDER BY bib, role |}
      competition
  with
  | l -> conv_all_bibs l
  | exception Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND -> []

let insert_row ~st ~competition ~dancer ~role ~bib =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;int;int;int]
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
  State.insert ~st ~ty:[int;int]
    {| DELETE FROM bibs WHERE competition_id = ? AND bib = ? |}
    competition bib

