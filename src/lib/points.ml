
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definition *)
(* ************************************************************************* *)

type t = int

type placement =
  | Finals of Rank.t option
  | Semifinals
  | Other


(* Base rules *)
(* ************************************************************************* *)

type baserule = {
  finals : t array;
  semifinals : t;
}

let base finals ~semis =
  { finals; semifinals = semis; }

let apply rule = function
  | Finals Some rank ->
    let i = Rank.to_index rank in
    if i <= (Array.length rule.finals) - 1
    then rule.finals.(i)
    else 0
  | Semifinals -> rule.semifinals
  | Finals None | Other -> 0


(* Points won by date/placement/number of competitors *)
(* ************************************************************************* *)

module IM = Interval.Map.Make(struct
    type t = int
    let compare = compare
    let print = Format.pp_print_int
  end)

type rule = baserule IM.t

type rules = rule Date.Itm.t

let rules : rules =
  Date.Itm.of_list [
    Date.mk ~day:1 ~month:1 ~year:2000,
    IM.of_list [
      1, base [| 7; 5; 3 |] ~semis:0;
      11, base [| 10; 8; 6; 3; 3 |] ~semis:0;
      21, base [| 12; 10; 8; 6; 6; 3; 3; 3; 3; 3 |] ~semis:0;
      31, base [| 14; 12; 10; 8; 8; 6; 6; 3; 3; 3 |] ~semis:2;
      46, base [| 16; 14; 12; 10; 10; 8; 8; 6; 6; 6 |] ~semis:3;
    ];
    Date.mk ~day:1 ~month:1 ~year:2025,
    IM.of_list [
        1, base [| 7; 5; 3 |] ~semis:0;
        11, base [| 10; 8; 6; 3; 3 |] ~semis:0;
        21, base [| 12; 10; 8; 6; 6; 3; 3; 3; 3; 3 |] ~semis:0;
        31, base [| 14; 12; 10; 8; 8; 6; 6; 3; 3; 3 |] ~semis:1;
        46, base [| 16; 14; 12; 10; 10; 8; 8; 6; 6; 6 |] ~semis:2;
      ];
    Date.mk ~day:9 ~month:7 ~year:2025,
    IM.of_list [
        1, base [| 6; 4; 2 |] ~semis:0;
        11, base [| 8; 6; 4; 2; 1 |] ~semis:0;
        21, base [| 10; 8; 6; 4; 2; 1; 1; 1; 1; 1 |] ~semis:0;
        31, base [| 12; 10; 8; 6; 4; 2; 2; 2; 2; 2 |] ~semis:1;
        46, base [| 14; 12; 10; 8; 6; 4; 4; 4; 2; 2 |] ~semis:1;
        66, base [| 16; 14; 12; 10; 8; 6; 6; 6; 4; 4; 2; 2; 2; 2 |] ~semis:1;
      ];
  ]

let find ~date ~n ~placement =
  match Date.Itm.find_opt rules date with
  | None ->
    assert false (* TODO: error message ? this is an internal failure *)
  | Some rule ->
    begin match IM.find_opt rule n with
      | None -> assert false (* TODO: error message *)
      | Some baserule -> apply baserule placement
    end

