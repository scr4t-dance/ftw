
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type & usual functions *)
(* ************************************************************************* *)

type 'a t =
  | Conv : ('b, 'a) Sqlite3_utils.Ty.t * 'b -> 'a t

let mk p res = Conv (p, res)


(* Misc *)
(* ************************************************************************* *)

let (@>>) = Sqlite3_utils.Ty.(@>>)

let int = mk Sqlite3_utils.Ty.([int]) (fun i -> i)


