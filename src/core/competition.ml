
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t

type status =
 | Setup
 | Registration
 | Distribution
 | Progress
 | Finished

type t = {
  id : id;
  event : Event.id;
  status : status;
  name : string;
  kind : Kind.t;
  category : Category.t;
  n_leaders : int;
  n_follows : int;
  check_divs : bool;
  public : bool;
}


(* Common functions *)
(* ************************************************************************* *)

let id { id; _ } = id
let event { event; _ } = event
let status { status; _ } = status
let public { public; _ } = public
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

  let with_status status t = { t with status; }

  let mk ~id ~event ~status ~public ~name ~kind ~category
      ~n_leaders ~n_follows ?(check_divs = true) () =
    { id; event; status; public; name; kind; category; n_leaders; n_follows; check_divs; }

end
