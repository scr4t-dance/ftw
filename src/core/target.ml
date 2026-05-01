
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type single = [ `Single ]
type couple = [ `Couple ]
type trouple = [ `Trouple ]

type kind = [ single | couple | trouple ]

type ('kind, 'a) t =
  | Single :
      { target : 'a; role : Role.t; } -> (single, 'a) t
  | Couple :
      { leader : 'a; follower : 'a; } -> (couple, 'a) t
  | Trouple :
      { dancer1 : 'a; dancer2 : 'a; dancer3 : 'a; } -> (trouple, 'a) t

type 'a any = Any : (_, 'a) t -> 'a any


(* Usual functions *)
(* ************************************************************************* *)

let map (type kind a b) ~f:(f: (a -> b)) (t : (kind, a) t) : (kind, b) t =
  match t with
  | Single { target; role; } ->
    Single { target = f target; role; }
  | Couple { leader; follower; } ->
    Couple { leader = f leader; follower = f follower; }
  | Trouple { dancer1; dancer2; dancer3; } ->
    Trouple { dancer1 = f dancer1; dancer2 = f dancer2; dancer3 = f dancer3; }

let map_any ~f (Any target) = Any (map ~f target)

let print_single pp fmt (Single { target; role; }) =
  Format.fprintf fmt "%a:%a" Role.print_compact role pp target

let print_couple pp fmt (Couple { leader; follower; }) =
  Format.fprintf fmt "%a & %a" pp leader pp follower

let print_trouple pp fmt (Trouple {dancer1; dancer2; dancer3; }) =
  Format.fprintf fmt "%a & %a & %a" pp dancer1 pp dancer2 pp dancer3

let print pp fmt = function
  | Any (Single _ as s) -> print_single pp fmt s
  | Any (Couple _ as c) -> print_couple pp fmt c
  | Any (Trouple _ as t) -> print_trouple pp fmt t


(* Serialization *)
(* ************************************************************************* *)

let to_toml (Any t) =
  match t with
  | Single { target; role; } ->
    Otoml.inline_table [
      "target", Id.to_toml target;
      "role", Role.to_toml role;
    ]
  | Couple { leader; follower; } ->
    Otoml.inline_table [
      "leader", Id.to_toml leader;
      "follower", Id.to_toml follower;
    ]
  | Trouple { dancer1; dancer2; dancer3; } ->
    Otoml.inline_table [
      "dancer1", Id.to_toml dancer1;
      "dancer2", Id.to_toml dancer2;
      "dancer3", Id.to_toml dancer3;
    ]

let of_toml_single t =
  let open Misc.Opt in
  let+ target = Otoml.find_opt t Id.of_toml ["target"] in
  let+ role = Otoml.find_opt t Role.of_toml ["role"] in
  Some (Single { target; role})

let of_toml_couple t =
  let open Misc.Opt in
  let+ leader = Otoml.find_opt t Id.of_toml ["leader"] in
  let+ follower = Otoml.find_opt t Id.of_toml ["follower"] in
  Some (Couple { leader; follower; })

let of_toml_trouple t =
  let open Misc.Opt in
  let+ dancer1 = Otoml.find_opt t Id.of_toml ["dancer1"] in
  let+ dancer2 = Otoml.find_opt t Id.of_toml ["dancer2"] in
  let+ dancer3 = Otoml.find_opt t Id.of_toml ["dancer3"] in
  Some (Trouple { dancer1; dancer2; dancer3; })

let of_toml t =
  match of_toml_single t with
  | Some single -> Any single
  | None ->
    match of_toml_couple t with
    | Some couple -> Any couple
    | None ->
      match of_toml_trouple t with
      | Some trouple -> Any trouple
      | None -> raise (Otoml.Type_error "not a bib target")


