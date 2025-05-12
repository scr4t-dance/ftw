
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t = Id.t

type 'kind target =
  | Single :
      { target : Id.t; role : Role.t; } -> [`Single] target
  | Couple :
      { leader : Id.t; follower : Id.t; } -> [`Couple] target

type any_target = Any : _ target -> any_target

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

let row_to_string row = Printf.sprintf "(dancer: %d, competition: %d, bib: %d, role: %d)"
    row.dancer_id row.competition_id row.bib (Role.to_int row.role)

let bib_of_rows rows =
  match rows with
  (* Single case *)
  | [ { dancer_id = target; role; _ } ] ->
    Ok (Some (Any (Single { target; role; })))
  (* Couple case 1*)
  | [ { dancer_id = leader; role = Leader; bib = leader_bib; competition_id = competition_id_leader; };
      { dancer_id = follower; role = Follower; bib = follower_bib; competition_id = competition_id_follower; } ]
    when leader_bib = follower_bib && competition_id_leader = competition_id_follower ->
    Ok (Some (Any (Couple { leader; follower; })))
  (* Couple case 2*)
  | [ { dancer_id = follower; role = Follower; bib = follower_bib; competition_id = competition_id_follower; };
      { dancer_id = leader; role = Leader; bib = leader_bib; competition_id = competition_id_leader; } ]
    when leader_bib = follower_bib && competition_id_leader = competition_id_follower ->
    Ok (Some (Any (Couple { leader; follower; })))
  (* ensure identical competition id. *)
  | [ { competition_id = competition_id_leader; _ };
      { competition_id = competition_id_follower; _ } ]
    when competition_id_leader != competition_id_follower ->
    Error "Expected a unique competition_id, got two."
  (* ensure identical bib id. *)
  | [ { bib = leader_bib; competition_id = competition_id_leader; _ };
      { bib = follower_bib; competition_id = competition_id_follower; _ } ]
    when leader_bib != follower_bib && competition_id_leader = competition_id_follower ->
    Error "Expected a unique bib id, got two"
  | [] -> Ok None
  | exception Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND -> Ok None
  (* This is an error (wrongly formatted database *)
  | x -> Error (
      Printf.sprintf "Got %d elements, expected 0, 1, or 2. List of value is:\n* " (List.length x)
      ^ String.concat "\n* " (List.map row_to_string x)
    )


let conv =
  Conv.mk Sqlite3_utils.Ty.[int;int;int;int]
    (fun dancer_id competition_id bib role ->
       let role = Role.of_int role in
       { dancer_id; competition_id; bib; role; }
    )

let get ~st ~competition ~bib =
  let open Sqlite3_utils.Ty in
  let rows = State.query_list_where ~st ~conv ~p:[int;int]
      {| SELECT * FROM bibs WHERE bib = ? AND competition_id = ? |}
      bib competition
  in
  bib_of_rows rows

let list_from_comp ~st ~competition =
  let update_aux acc (r : row) =
    let new_value = match Id.Map.find_opt r.bib acc with
      | None -> [r]
      | Some l -> r::l
    in
    Id.Map.add r.bib new_value acc
  in
  let open Sqlite3_utils.Ty in
  let row_list =
    State.query_list_where ~st ~conv ~p:[int]
      {| SELECT * FROM bibs WHERE competition_id = ? ORDER BY dancer_id |}
      competition
  in
  let row_map = List.fold_left update_aux Id.Map.empty row_list in
  let target_option_result_map = Id.Map.map bib_of_rows row_map in
  let target_option_map_result = Id.Map.fold
      (fun key value acc -> match value, acc with
         | Ok v, Ok a -> Ok (Id.Map.add key v a)
         | Error e, Ok _ -> Error e
         | Ok _, Error e -> Error e
         | Error e, Error ae -> Error (ae ^ "\n" ^ e)
      )
      target_option_result_map (Ok Id.Map.empty)
  in
  let target_map_result = Result.map (Id.Map.filter_map (fun _ v -> v)) target_option_map_result
  in
  target_map_result


let insert_row ~st ~competition ~dancer ~role ~bib =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;int;int;int]
    {| INSERT INTO bibs(dancer_id,competition_id,bib,role) VALUES (?,?,?,?) |}
    dancer competition bib (Role.to_int role)

let insert_target ~st ~competition ~target ~bib =
  match target with
  | Any Single { target; role; } ->
    insert_row ~st ~bib ~competition ~dancer:target ~role
  | Any Couple { leader; follower; } ->
    insert_row ~st ~bib ~competition ~dancer:leader ~role:Leader;
    insert_row ~st ~bib ~competition ~dancer:follower ~role:Follower

let set ~st ~competition ~target ~bib =
  let existing_target = get ~st ~competition ~bib in
  begin match existing_target with
    | Ok Some _ -> assert false
    | Ok None -> ()
    | Error _ -> assert false
  end;
  insert_target ~st ~competition ~target ~bib


let update ~st ~competition ~target ~bib =
  let existing_target = get ~st ~competition ~bib in
  begin match existing_target with
    | Ok Some _ ->
      let open Sqlite3_utils.Ty in
      State.insert ~st ~ty:[int;int]
        {| DELETE FROM bibs
        WHERE 0=0
        AND competition_id = ?
        AND bib = ?
        |}
        competition bib
    | Ok None -> raise Not_found
    | Error e -> raise (Failure e)
  end;
  insert_target ~st ~competition ~target ~bib

let delete_bib ~st ~competition ~bib =
  let existing_target = get ~st ~competition ~bib in
  begin match existing_target with
    | Ok Some Any (Single starget) -> Logs.warn (fun k->
        k "Delete target: %d %d with bib %d" starget.target (Role.to_int starget.role) bib); flush_all();
    | Ok Some Any (Couple ctarget) -> Logs.warn (fun k->
        k "Delete target: leader %d folllower %d with bib %d" ctarget.leader ctarget.follower bib); flush_all();
    | Ok None -> raise Not_found
    | Error e -> raise (Failure e)
  end;
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;int]
    {| DELETE FROM bibs
    WHERE 0=0
    AND competition_id = ?
    AND bib = ?
    |}
    competition bib
