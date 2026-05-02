
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Round


(* Serialization *)
(* ************************************************************************* *)

let to_string = function
  | Prelims -> "prelims"
  | Finals -> "finals"
  | Semifinals -> "semifinals"
  | Quarterfinals -> "quarterfinals"
  | Octofinals -> "octofinals"

let toml_key t = to_string t

(* DB interaction *)
(* ************************************************************************* *)

let to_int = function
  | Finals -> 0
  | Prelims -> 1
  | Semifinals-> 2
  | Quarterfinals -> 3
  | Octofinals -> 4

let of_int = function
  | 0 -> Finals
  | 1 -> Prelims
  | 2 -> Semifinals
  | 3 -> Quarterfinals
  | 4 -> Octofinals
  | _ -> assert false

let p = Sqlite3_utils.Ty.([int])
let conv = Conv.mk p of_int

let () =
  State.add_init_descr_table ()
    ~table_name:"round_names" ~to_int
    ~to_descr:to_string ~db:Main
    ~values:[
      Prelims; Finals;
      Semifinals;
      Quarterfinals;
      Octofinals;
    ]



