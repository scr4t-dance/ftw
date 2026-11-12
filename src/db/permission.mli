
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Checking permission *)
(* ************************************************************************* *)

val check : st:State.t -> ?user:User.t -> Lib.Permission.t -> bool

