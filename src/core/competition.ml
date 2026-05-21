
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


(* Some logic *)
(* ************************************************************************* *)

let round_count t round =
  let n_l = n_leaders t in
  let n_f = n_follows t in
  let n_max = max n_l n_f in
  match kind t with
  | Jack_and_Jill when n_max <= 10 ->
    begin match (round : Round.t) with
      | Finals -> -1
      | _ -> 0
    end
  | Jack_and_Jill when 11 <= n_max && n_max <= 20 ->
    begin match (round : Round.t) with
      | Prelims -> -1
      | Finals -> 5
      | _ -> 0
    end
  | Jack_and_Jill when 21 <= n_max && n_max <= 30 ->
    begin match (round : Round.t) with
      | Prelims -> -1
      | Finals -> 10
      | _ -> 0
    end
  | Jack_and_Jill when 31 <= n_max && n_max <= 45 ->
    begin match (round : Round.t) with
      | Prelims -> -1
      | Semifinals -> 16
      | Finals -> 10
      | _ -> 0
    end
  | Jack_and_Jill when 46 <= n_max && n_max <= 65 ->
    begin match (round : Round.t) with
      | Prelims -> -1
      | Semifinals -> 24
      | Finals -> 10
      | _ -> 0
    end
  | Jack_and_Jill when 66 <= n_max ->
    begin match (round : Round.t) with
      | Prelims -> -1
      | Semifinals -> 32
      | Finals -> 14
      | _ -> 0
    end
  | _ -> 0

let rec next_round t round_opt =
  let aux r =
    let n = round_count t r in
    if n = 0
    then next_round t (Some r)
    else r, n
  in
  match round_opt with
  | None -> aux Prelims
  | Some Prelims -> aux Octofinals
  | Some Octofinals -> aux Quarterfinals
  | Some Quarterfinals -> aux Semifinals
  | Some Semifinals -> aux Finals
  | Some Finals -> assert false


(* Private functions *)
(* ************************************************************************* *)

module Private = struct

  let with_status status t = { t with status; }

  let with_n ~leaders ~followers t = 
    { t with n_leaders = leaders; n_follows = followers; }

  let mk ~id ~event ~status ~public ~name ~kind ~category
      ~n_leaders ~n_follows ?(check_divs = true) () =
    { id; event; status; public; name; kind; category; n_leaders; n_follows; check_divs; }

end
