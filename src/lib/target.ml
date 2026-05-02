
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Target

(* Serialization *)
(* ************************************************************************* *)

let to_toml ~to_toml (Any t) =
  match t with
  | Single { target; role; } ->
    Otoml.inline_table [
      "target", to_toml target;
      "role", Role.to_toml role;
    ]
  | Couple { leader; follower; } ->
    Otoml.inline_table [
      "leader", to_toml leader;
      "follower", to_toml follower;
    ]
  | Trouple { target1; target2; target3; } ->
    Otoml.inline_table [
      "target1", to_toml target1;
      "target2", to_toml target2;
      "target3", to_toml target3;
    ]

let single_of_toml ~of_toml t =
  let open Ftw_core.Misc.Opt in
  let+ target = Otoml.find_opt t of_toml ["target"] in
  let+ role = Otoml.find_opt t Role.of_toml ["role"] in
  Some (Single { target; role})

let couple_of_toml ~of_toml t =
  let open Ftw_core.Misc.Opt in
  let+ leader = Otoml.find_opt t of_toml ["leader"] in
  let+ follower = Otoml.find_opt t of_toml ["follower"] in
  Some (Couple { leader; follower; })

let trouple_of_toml ~of_toml t =
  let open Ftw_core.Misc.Opt in
  let+ target1 = Otoml.find_opt t of_toml ["target1"] in
  let+ target2 = Otoml.find_opt t of_toml ["target2"] in
  let+ target3 = Otoml.find_opt t of_toml ["target3"] in
  Some (Trouple { target1; target2; target3; })

let of_toml ~of_toml t =
  match single_of_toml ~of_toml t with
  | Some single -> Any single
  | None ->
    match couple_of_toml ~of_toml t with
    | Some couple -> Any couple
    | None ->
      match trouple_of_toml ~of_toml t with
      | Some trouple -> Any trouple
      | None -> raise (Otoml.Type_error "not a bib target")

(* Serialization *)
(* ************************************************************************* *)

module With_id = struct

  include Ftw_core.Target.With_id

  let to_toml ~to_toml (Any { target; id; }) =
    match target with
    | Single { target; role; } ->
      Otoml.inline_table [
        "id", Id.to_toml id;
        "target", to_toml target;
        "role", Role.to_toml role;
      ]
    | Couple { leader; follower; } ->
      Otoml.inline_table [
        "id", Id.to_toml id;
        "leader", to_toml leader;
        "follower", to_toml follower;
      ]
    | Trouple { target1; target2; target3; } ->
      Otoml.inline_table [
        "id", Id.to_toml id;
        "target1", to_toml target1;
        "target2", to_toml target2;
        "target3", to_toml target3;
      ]

  let single_of_toml ~of_toml t =
    let open Ftw_core.Misc.Opt in
    let+ id = Otoml.find_opt t Id.of_toml ["id"] in
    let+ target = Otoml.find_opt t of_toml ["target"] in
    let+ role = Otoml.find_opt t Role.of_toml ["role"] in
    Some ({ id; target = Single { target; role; }})

  let couple_of_toml ~of_toml t =
    let open Ftw_core.Misc.Opt in
    let+ id = Otoml.find_opt t Id.of_toml ["id"] in
    let+ leader = Otoml.find_opt t of_toml ["leader"] in
    let+ follower = Otoml.find_opt t of_toml ["follower"] in
    Some ({ id; target = Couple { leader; follower; }; })

  let trouple_of_toml ~of_toml t =
    let open Ftw_core.Misc.Opt in
    let+ id = Otoml.find_opt t Id.of_toml ["id"] in
    let+ target1 = Otoml.find_opt t of_toml ["target1"] in
    let+ target2 = Otoml.find_opt t of_toml ["target2"] in
    let+ target3 = Otoml.find_opt t of_toml ["target3"] in
    Some ({ id; target = Trouple { target1; target2; target3; }; })

  let of_toml ~of_toml t =
    match single_of_toml ~of_toml t with
    | Some single -> Any single
    | None ->
      match couple_of_toml ~of_toml t with
      | Some couple -> Any couple
      | None ->
        match trouple_of_toml ~of_toml t with
        | Some trouple -> Any trouple
        | None -> raise (Otoml.Type_error "not a bib target")

end
