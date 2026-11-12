
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* convenient type alias *)
type 'a res = ('a, Error.t) result

(* Result helpers *)
(* ************************************************************************* *)

let product r0 r1 =
  match r0, r1 with
  | (Error _ as r), _
  | _, (Error _ as r) -> r
  | Ok v0, Ok v1 -> Ok (v0, v1)

(* Error helpers *)
(* ************************************************************************* *)

let ok x =
  Ok x

let err descr =
  Error (Error.mk descr)

let msg = Format.dprintf

let with_ctx frame f =
  match f () with
  | Ok _ as res -> res
  | Error err -> Error (Error.push frame err)


(* Monadic and infix/prefix operators *)
(* ************************************************************************* *)

(* for result *)
let ( let* ) = Result.bind
let ( and* ) = product
let ( let+ ) = Result.map
let ( and+ ) = product

(* for errors *)
let ( %> ) = Error.frame
let ( let@ ) = with_ctx

