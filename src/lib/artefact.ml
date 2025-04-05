
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Artefact descriptions *)
(* ************************************************************************* *)

module Descr = struct

  type t =
    | Ranking
    | Yans of { criterion : string list; }
  [@@deriving yojson]

  let ranking = Ranking
  let yans criterion = Yans { criterion; }

end

(* Artefact values *)
(* ************************************************************************* *)

type yan =
  | Yes
  | Alt
  | No (**)
(* Yes/Alt/No *)

type t =
  | Rank of Rank.t
  | Yans of yan list


(* Encoding and decoding *)
(* ************************************************************************* *)

(* Int encoding schema:

   The FTW db will store a very large number of artefacts (in the order of a
   few thousands for each competition). Therefore the encoding of artefacts is
   designed to take as little space as possible. This is possible because
   SQlite stores integers using between 1 and 8 bytes depending on the
   magnitude of the stored integers. In other words, small enough integers are
   stored using less space.

   Since each competition phase has in its configuration a description of the
   stored (and expected) artefacts, we can also require the description of an
   artefact in order to decode it (i.e. use a tagless encoding), saving a
   precious few bits, and ensure that almost always, an encoded artefact can
   fit in a single byte. *)


let of_int ~descr v =
  (* constant-size YAN encoded using the [i] and [i+1] least significant bits. *)
  let[@inline] decode_yan v i =
    if Misc.Bit.is_set ~index:i v then
      if Misc.Bit.is_set ~index:(i + 1) v then
        Yes
      else
        Alt
    else
      No
  in
  match (descr : Descr.t) with
  | Ranking -> Rank v
  | Yans { criterion; } ->
    let rec aux v i = function
      | [] -> []
      | _ :: r -> decode_yan v i :: aux v (i + 2) r
    in
    let yans = (aux[@unrolled 4]) v 0 criterion in
    Yans yans

let to_int t =
  let encode_yan v i y =
    assert (not (Misc.Bit.is_set ~index:i v) &&
            not (Misc.Bit.is_set ~index:(i + 1) v));
    match y with
    | Yes -> v |> Misc.Bit.set ~index:i |> Misc.Bit.set ~index:(i + 1)
    | Alt -> v |> Misc.Bit.set ~index:i
    | No -> v
  in
  match (t : t) with
  | Rank r -> r
  | Yans l ->
    fst @@ List.fold_left
      (fun (v, i) y -> (encode_yan v i y, i + 2)) (0, 0) l


(* DB interaction *)
(* ************************************************************************* *)

let p = Sqlite3_utils.Ty.([int])
let conv ~descr = Conv.mk p (of_int ~descr)

let () =
  State.add_init (5, fun st ->
      State.exec ~st {|
        CREATE TABLE IF NOT EXISTS artefacts (
          target_id INTEGER REFERENCES heats(id),
          judge INTEGER REFERENCES dancers(id),
          artefact INTEGER NOT NULL,
          PRIMARY KEY(target_id,judge)
        )
      |})

let get ~st ~judge ~target ~descr =
  let open Sqlite3_utils.Ty in
  State.query_one_where ~st ~p:[int;int] ~conv:(conv ~descr)
    {| SELECT artefact FROM artefacts WHERE target_id = ? AND judge = ? |}
    target judge

let set ~st ~judge ~target t =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;int;int]
    {| INSERT INTO artefacts(target_id,judge,artefact) VALUES (?,?,?) |}
    target judge (to_int t)
