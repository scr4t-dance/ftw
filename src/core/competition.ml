
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t

type t = {
  id : id;
  event : Event.id;
  name : string;
  kind : Kind.t;
  category : Category.t;
  n_leaders : int;
  n_follows : int;
  check_divs : bool;
}


(* Common functions *)
(* ************************************************************************* *)

let id { id; _ } = id
let event { event; _ } = event
let name { name; _ } = name
let kind { kind; _ } = kind
let category { category; _ } = category
let n_leaders { n_leaders; _ } = n_leaders
let n_follows { n_follows; _ } = n_follows
let check_divs { check_divs; _ } = check_divs

let print_compact fmt t =
  if t.name <> "" then Format.fprintf fmt "%s" t.name
  else Format.fprintf fmt "%a %a" Kind.print t.kind Category.print t.category


(* Private functions *)
(* ************************************************************************* *)

module Private = struct

  let mk ~id ~event ~name ~kind ~category
      ~n_leaders ~n_follows ?(check_divs = true) () =
    { id; event; name; kind; category; n_leaders; n_follows; check_divs; }

end
