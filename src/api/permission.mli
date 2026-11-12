
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type defs *)
(* ************************************************************************* *)

include (module type of struct include Lib.Permission end)

type Lib.Error.descr +=
  | Forbidden of {
      user : User.t option;
      perm : t;
    }

(* Checking permissions *)
(* ************************************************************************* *)

val check : st:State.t -> ?user:User.t -> t -> bool

val ensure : st:State.t -> ?user:User.t -> t -> unit Syntax.res

