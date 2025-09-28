
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

  let print fmt = function
    | Ranking ->
      Format.fprintf fmt "Ranking"
    | Yans { criterion } ->
      let pp_sep fmt () = Format.fprintf fmt ";@ " in
      Format.fprintf fmt "Yans(@[<hov>%a@])"
        (Format.pp_print_list ~pp_sep Format.pp_print_string) criterion

  let to_toml = function
    | Ranking ->
      Otoml.array [ Otoml.string "Ranking" ]
    | Yans { criterion } ->
      Otoml.array (
        Otoml.string "Yans" ::
        List.map Otoml.string criterion)

  let of_toml t =
    match Otoml.(get_array get_value) t with
    | [ t' ] when Otoml.(get_opt get_string) t' = Some "Ranking" ->
      Ranking
    | t' :: r when Otoml.(get_opt get_string) t' = Some "Yans" ->
      let criterion = List.map Otoml.get_string r in
      Yans { criterion }
    | _ ->
      raise (Otoml.Type_error "Incorrect encoding of Artefact.Descr.t")

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
  State.add_init ~name:"artefact" (fun st ->
      State.exec ~st {|
        CREATE TABLE IF NOT EXISTS artefacts (
          target_id INTEGER REFERENCES heats(id),
          judge INTEGER REFERENCES dancers(id),
          artefact INTEGER NOT NULL,
          PRIMARY KEY(target_id,judge)
          ON CONFLICT REPLACE
        )
      |})

(* Note: the target here is a Heat.target_id;
    however we cannot put these annotations explicitly because
    of circular dependencies *)
let get ~st ~judge ~target ~descr =
  let open Sqlite3_utils.Ty in
  let artefact_list = State.query_list_where ~st ~p:[int;int] ~conv:(conv ~descr)
      {| SELECT artefact FROM artefacts WHERE target_id = ? AND judge = ? |}
      target judge
  in
  match artefact_list with
  | [] -> Ok None
  | [a] -> Ok (Some a)
  | _ -> Error "Too many artefact found for target"


let set ~st ~judge ~target t =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;int;int]
    {| INSERT INTO artefacts(target_id,judge,artefact) VALUES (?,?,?) |}
    target judge (to_int t);
  Ok target

let delete ~st ~judge ~target =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;int]
    {| DELETE FROM artefacts
    WHERE 0=0
    AND target_id = ?
    AND judge = ? |}
    target judge;
  Ok target


(* Serialization *)
(* ************************************************************************* *)

let yan_to_toml = function
  | Yes -> Otoml.integer 3
  | Alt -> Otoml.integer 2
  | No -> Otoml.integer 1

let yan_of_toml t =
  match Otoml.get_integer t with
  | 1 -> No
  | 2 -> Alt
  | 3 -> Yes
  | i -> raise (Otoml.Type_error ("Not a Yan: " ^ (string_of_int i)))

let yans_to_toml l = Otoml.array (List.map yan_to_toml l)
let yans_of_toml t = Otoml.get_array yan_of_toml t

let to_toml = function
  | Rank i -> Rank.to_toml i
  | Yans l -> yans_to_toml l

let of_toml ~descr t =
  match (descr : Descr.t) with
  | Ranking -> Rank (Rank.of_toml t)
  | Yans _ -> Yans (yans_of_toml t)
