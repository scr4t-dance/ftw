
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t

type t = {
  id : id;
  birthday : Date.t option;
  last_name : string;
  first_name : string;
  email : string option;
  as_leader : Divisions.t;
  as_follower : Divisions.t;
}

(* Accessors *)
(* ************************************************************************* *)

let id { id; _ } = id
let birthday { birthday; _ } = birthday
let last_name { last_name; _ } = last_name
let first_name { first_name; _ } = first_name
let email { email; _ } = email
let as_leader { as_leader; _ } = as_leader
let as_follower { as_follower; _ } = as_follower

let print_compact fmt t =
  Format.fprintf fmt "%s %s" t.first_name t.last_name

let print_divs role fmt divs =
  match (divs : Divisions.t) with
  | None -> ()
  | _ ->
    Format.fprintf fmt "%a:%a" Role.print_compact role Divisions.print divs

let print_opt pp fmt = function
  | None -> ()
  | Some x -> Format.fprintf fmt "(%a)" pp x

let print fmt t =
  Format.fprintf fmt "%s %s %a%a%s%a%a"
    t.first_name t.last_name
    (print_divs Leader) t.as_leader
    (print_divs Follower) t.as_follower
    (match t.as_leader, t.as_follower with
     | None, None -> "divs:N/A" | _ -> "")
    (print_opt Date.print) t.birthday
    (print_opt Format.pp_print_string) t.email

(* Private functions *)
(* ************************************************************************* *)

module Private = struct

  let mk ~id ~last_name ~first_name
      ~birthday ~email ~as_leader ~as_follower =
    { id; birthday; last_name; first_name; email; as_leader; as_follower; }

end

