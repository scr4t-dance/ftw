
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* TODO: more doc *)

(* Type definitions & creation *)
(* ************************************************************************* *)

type 'a t = private
  | Conv : ('b, 'a) Sqlite3_utils.Ty.t * 'b -> 'a t


val mk : ('a, 'b) Sqlite3_utils.Ty.t -> 'a -> 'b t


(* Useful dfinitions *)
(* ************************************************************************* *)

val (@>>) :
  ('a, 'b) Sqlite3_utils.Ty.t ->
  ('b, 'c) Sqlite3_utils.Ty.t ->
  ('a, 'c) Sqlite3_utils.Ty.t

val int : int t
