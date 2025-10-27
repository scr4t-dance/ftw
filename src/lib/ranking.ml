
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type description *)
(* ************************************************************************* *)
(*
type ('target, 'acc) target = {
  target : 'target;
  heat_target_id : Id.t; (* = Heat.target_id *)
  ranking_acc : 'acc;
}

type ('target, 'acc) ranked =
  | Rank of ('target, 'acc) target
  | Tie of {
      rank : int;
      tie : ('target, 'acc) target array;
    }

type ('target, 'acc) t = ('target, 'acc) ranked array

type status = Ranked | Tied


(* Printing functions *)
(* ************************************************************************* *)

let target n t =
  match t.(n) with
  | Rank target -> Ranked, n, target
  | Tie { rank; tie; } -> Tied, rank, tie.(n - rank)

let grid_init ~pp t ~line ~col =
  let status, rank, target = target line t in
  match col, status with
  | `Rank, Ranked -> PrintBox.int rank
  | `Rank, Tied ->
    PrintBox.asprintf_with_style
      { PrintBox.Style.default with bold = true; fg_color = Some Red; }
      "%d" rank
  | `Heat_target_id, _ ->
    PrintBox.asprintf "%d" target.heat_target_id
  | `Target, _ -> pp target.target
  | _ -> assert false
*)

(* Algorithms for creating rankings *)
(* ************************************************************************* *)

module Algorithm = struct

  type yan_weight = {
    yes : int;
    alt : int;
    no : int;
  } [@@deriving yojson]

  type t =
    | RPSS
    | Yan_weighted of {
        weights : yan_weight list;
        head_weights : yan_weight list;
      }
  [@@deriving yojson]

  (* Usual functions *)
  (* *********************************************************************** *)

  let print_yan_weight fmt { yes; alt; no; } =
    Format.fprintf fmt "%d/%d/%d" yes alt no

  let print_yan_weights fmt l =
    match Misc.Lists.all_the_same ~eq:(=) l with
    | Some t when List.length l > 1 ->
      Format.fprintf fmt "@@(%a)" print_yan_weight t
    | _ ->
      let pp_sep fmt () = Format.fprintf fmt ",@ " in
      Format.pp_print_list ~pp_sep print_yan_weight fmt l

  let print fmt = function
    | RPSS ->
      Format.fprintf fmt "RPSS"
    | Yan_weighted { weights; head_weights; } ->
      Format.fprintf fmt "%a / %a"
        print_yan_weights weights
        print_yan_weights head_weights


  (* Algorithms Serialization *)
  (* *********************************************************************** *)

  let yan_weight_to_toml { yes; alt; no; } =
    Otoml.inline_table [
      "yes", Otoml.integer yes;
      "alt", Otoml.integer alt;
      "no", Otoml.integer no;
    ]

  let yan_weight_of_toml t =
    let yes = Otoml.find_exn t Otoml.get_integer ["yes"] in
    let alt = Otoml.find_exn t Otoml.get_integer ["alt"] in
    let no = Otoml.find_exn t Otoml.get_integer ["no"] in
    { yes; alt; no; }

  let yan_weights_to_toml l =
    Otoml.array (List.map yan_weight_to_toml l)

  let yan_weights_of_toml t =
    Otoml.get_array yan_weight_of_toml t

  let to_toml = function
    | RPSS ->
      Otoml.array [ Otoml.string "RPSS"; ]
    | Yan_weighted { weights; head_weights; } ->
      Otoml.array [ Otoml.string "Yan_weighted";
                    yan_weights_to_toml weights;
                    yan_weights_to_toml head_weights ]

  let of_toml t =
    match Otoml.get_array Otoml.get_value t with
    | [ s ] when Otoml.get_opt Otoml.get_string s = Some "RPSS" ->
      RPSS
    | [ s; w; h_w ] when Otoml.get_opt Otoml.get_string s = Some "Yan_weighted" ->
      let weights = yan_weights_of_toml w in
      let head_weights = yan_weights_of_toml h_w in
      Yan_weighted { weights; head_weights; }
    | _ ->
      raise (Otoml.Type_error "Not a Ranking algorithm")


  (* Algorithms implementations *)
  (* *********************************************************************** *)

  (*
  module Yan_weighted = struct

    let get_artefacts ~st ~phase =
      State.query_list_where ~st ~conv:



  end
*)
end
