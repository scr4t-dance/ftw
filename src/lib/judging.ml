
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Judging

(* Serialization *)
(* ************************************************************************* *)

let to_string = function
  | Head { targets = _ } -> "Head"
  | Leaders -> "Leaders"
  | Followers -> "Followers"
  | Couples -> "Couples"


(* DB interaction *)
(* ************************************************************************* *)

let to_int = function
  | Head { targets = `Singles; } -> 0
  | Head { targets = `Couples; } -> 4
  | Leaders -> 1
  | Followers -> 2
  | Couples -> 3

let of_int = function
  | 0 -> Head { targets = `Singles }
  | 4 -> Head { targets = `Couples }
  | 1 -> Leaders
  | 2 -> Followers
  | 3 -> Couples
  | _ -> failwith "incorrect judging"

let p = Id.p

let conv =
  Conv.mk Sqlite3_utils.Ty.[int] of_int

let () =
  State.add_init_descr_table ()
    ~table_name:"judging_names" ~to_int
    ~to_descr:to_string ~db:Main ~values:[
      Head { targets = `Singles};
      Head { targets = `Couples};
      Couples; Leaders; Followers;
    ]

