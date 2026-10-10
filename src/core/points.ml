
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definition *)
(* ************************************************************************* *)

type t = int

type placement =
  | Finals of Rank.t
  | Semifinals of Rank.t
  | Other

let max (i : t) j = max i j

(* Base rules *)
(* ************************************************************************* *)

type baserule = {
  by_rank : t array;
}

let base ~finals ~semis_points ~semis_num =
  let n = semis_num - Array.length finals in
  let by_rank =
    if n <= 0 then finals
    else
      let semis = Array.make n semis_points in
      Array.append finals semis
  in
  { by_rank }

let apply rule = function
  | Finals rank | Semifinals rank ->
    let i = Rank.to_index rank in
    if i <= (Array.length rule.by_rank) - 1
    then rule.by_rank.(i)
    else 0
  | Other -> 0


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
      1, base
        ~semis_points:0 ~semis_num:0
        ~finals:[| 7; 5; 3 |];
      11, base
        ~semis_points:0 ~semis_num:0
        ~finals:[| 10; 8; 6; 3; 3 |];
      21, base
        ~semis_points:0 ~semis_num:0
        ~finals:[| 12; 10; 8; 6; 6; 3; 3; 3; 3; 3 |];
      31, base
        ~semis_points:2 ~semis_num:16
        ~finals:[| 14; 12; 10; 8; 8; 6; 6; 3; 3; 3 |];
      46, base
        ~semis_points:3 ~semis_num:24
        ~finals:[| 16; 14; 12; 10; 10; 8; 8; 6; 6; 6 |];
    ];
    Date.mk ~day:1 ~month:1 ~year:2025,
    IM.of_list [
      1, base
        ~semis_points:0 ~semis_num:0
         ~finals:[| 7; 5; 3 |];
      11, base
        ~semis_points:0 ~semis_num:0
        ~finals:[| 10; 8; 6; 3; 3 |];
      21, base
        ~semis_points:0 ~semis_num:0
        ~finals:[| 12; 10; 8; 6; 6; 3; 3; 3; 3; 3 |];
      31, base
        ~semis_points:1 ~semis_num:16
        ~finals:[| 14; 12; 10; 8; 8; 6; 6; 3; 3; 3 |];
      46, base
        ~semis_points:2 ~semis_num:24
        ~finals:[| 16; 14; 12; 10; 10; 8; 8; 6; 6; 6 |];
      ];
    Date.mk ~day:9 ~month:7 ~year:2025,
    IM.of_list [
      1, base
        ~semis_points:0 ~semis_num:0
        ~finals:[| 6; 4; 2 |];
      11, base
        ~semis_points:0 ~semis_num:0
        ~finals:[| 8; 6; 4; 2; 1 |];
      21, base
        ~semis_points:0 ~semis_num:0
        ~finals:[| 10; 8; 6; 4; 2; 1; 1; 1; 1; 1 |];
      31, base
        ~semis_points:1 ~semis_num:16
        ~finals:[| 12; 10; 8; 6; 4; 2; 2; 2; 2; 2 |];
      46, base
        ~semis_points:1 ~semis_num:24
        ~finals:[| 14; 12; 10; 8; 6; 4; 4; 4; 2; 2 |];
      66, base
        ~semis_points:1 ~semis_num:32
        ~finals:[| 16; 14; 12; 10; 8; 6; 6; 6; 4; 4; 2; 2; 2; 2 |];
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

