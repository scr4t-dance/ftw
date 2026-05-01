
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Head
  | Leaders
  | Followers
  | Couples

(* Serialization *)
(* ************************************************************************* *)

let to_string = function
  | Head -> "Head"
  | Leaders -> "Leaders"
  | Followers -> "Followers"
  | Couples -> "Couples"


(* DB interaction *)
(* ************************************************************************* *)

let to_int = function
  | Head -> 0
  | Leaders -> 1
  | Followers -> 2
  | Couples -> 3

let of_int = function
  | 0 -> Head
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
    ~to_descr:to_string ~values:[
      Head; Couples;
      Leaders; Followers;
    ]

