
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type description *)
(* ************************************************************************* *)

(*
type 'a t = 'a Target.t array array
type 'a ranking = 'a t (* alias for use later in this file *)


type 'a rank =
  | Ranked of 'a Target.t
  | Tie of {
      rank : int;
      tie : 'a Target.t array;
    }
*)

(* Access functions *)
(* ************************************************************************* *)


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

  (* TODO *)

end
