
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
  State.add_init (fun st ->
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

let get ~st ~competition ~bib =
  let open Sqlite3_utils.Ty in
  match
    State.query_list_where ~st ~conv ~p:[int;int]
      {| SELECT * FROM bibs WHERE bib = ? AND competition_id = ? ORDER BY role |}
      bib competition
  with
  (* Single case *)
  | [ { dancer_id = target; role; _ } ] ->
    Some (Any (Single { target; role; }))
  (* Couple cases;
     the "ORDER BY" clause in the SQL query should ensure the order. *)
  | [ { dancer_id = leader; role = Leader; _ };
      { dancer_id = follower; role = Follower; _ } ] ->
    Some (Any (Couple { leader; follower; }))
  (* Not in database *)
  | [] -> raise Not_found
  | exception Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND -> None
  (* This is an error (wrongly formatted database *)
  | _ -> assert false

let set_aux ~st ~competition ~dancer ~role ~bib =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;int;int;int]
    {| INSERT INTO bibs(dancer_id,competition_id,bib,role) VALUES (?,?,?,?) |}
    dancer competition bib (Role.to_int role)

let set ~st ~competition ~target ~bib =
  (* TODO: catch errors if we try to set a duplicate bib
           / or clear the bib before setting it *)
  match target with
  | Any Single { target; role; } ->
    set_aux ~st ~bib ~competition ~dancer:target ~role
  | Any Couple { leader; follower; } ->
    set_aux ~st ~bib ~competition ~dancer:leader ~role:Leader;
    set_aux ~st ~bib ~competition ~dancer:follower ~role:Follower

