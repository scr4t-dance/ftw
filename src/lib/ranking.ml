
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Ranking


(* Algorithms *)
(* ************************************************************************* *)


module Yan_weighted = struct

  include Ftw_core.Ranking.Yan_weighted

  (* serialization *)
  let weight_to_toml { yes; alt; no; } =
    Otoml.inline_table [
      "yes", Otoml.integer yes;
      "alt", Otoml.integer alt;
      "no", Otoml.integer no;
    ]

  let weight_of_toml t =
    let yes = Otoml.find_exn t Otoml.get_integer ["yes"] in
    let alt = Otoml.find_exn t Otoml.get_integer ["alt"] in
    let no = Otoml.find_exn t Otoml.get_integer ["no"] in
    { yes; alt; no; }

  let weights_to_toml l =
    Otoml.array (List.map weight_to_toml l)

  let weights_of_toml t =
    Otoml.get_array weight_of_toml t

  let conf_to_toml { weights; head_weights; } =
    [ weights_to_toml weights;
      weights_to_toml head_weights ]

  let conf_of_toml = function
    | [ w; h_w ] ->
      let weights = weights_of_toml w in
      let head_weights = weights_of_toml h_w in
      { weights; head_weights; }
    | _ ->
      assert false (* TODO: error msg *)


end

module Algorithm = struct

  include Ftw_core.Ranking.Algorithm

  let to_toml = function
    | RPSS () ->
      Otoml.array [ Otoml.string "RPSS"; ]
    | Yan_weighted conf ->
      Otoml.array ( Otoml.string "Yan_weighted" :: Yan_weighted.conf_to_toml conf)

  let of_toml t =
    match Otoml.get_array Otoml.get_value t with
    | s :: _ when Otoml.get_opt Otoml.get_string s = Some "RPSS" ->
      RPSS ()
    | s :: r when Otoml.get_opt Otoml.get_string s = Some "Yan_weighted" ->
      let conf = Yan_weighted.conf_of_toml r in
      Yan_weighted conf
    | _ ->
      raise (Otoml.Type_error "Not a Ranking algorithm")

end
