
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Users *)
(* ************************************************************************* *)

type id = Id.t

type hash = string

type t = {
  (* id *)
  id : id;

  (* core info *)
  name : string;
  email : string;

  (* link to FTW main db *)
  dancer_id : Dancer.id;
}

(* Std functions *)
(* ************************************************************************* *)

let id t = t.id
let name t = t.name
let email t = t.email
let dancer_id t = t.dancer_id

let mk id name email dancer_id =
  { id; name; email; dancer_id; }

let print fmt { id; name; email = _; dancer_id; } =
  Format.fprintf fmt "%d:%s(%d)" id name dancer_id

