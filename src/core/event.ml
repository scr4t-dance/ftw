
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t

type status =
  | Setup
  | In_progress
  | Finished

type t = {
  id : id;
  name : string;
  short_name : string;
  start_date : Date.t;
  end_date : Date.t;
  public : bool;
  status : status;
}

(* Common functions *)
(* ************************************************************************* *)

let id { id; _ } = id
let name { name; _ } = name
let short_name { short_name; _ } = short_name
let start_date { start_date; _ } = start_date
let end_date { end_date; _ } = end_date
let public { public; _ } = public
let status { status; _ } = status

(* comparison sorts by date first because it's more convenient,
   even if slightly less efficient. *)
let compare e e' =
  let open CCOrd in
  Date.compare (start_date e) (start_date e')
  <?> (Date.compare, (end_date e), (end_date e'))
  <?> (int, e.id, e'.id)

let print_compact fmt t =
  let start_year = Date.year t.start_date in
  let end_year = Date.year t.end_date in
  if start_year = end_year then
    Format.fprintf fmt "%s (%d)" t.name start_year
  else
    Format.fprintf fmt "%s (%d/%d)" t.name start_year end_year


(* Private functions *)
(* ************************************************************************* *)

module Private = struct

  let mk ~id ~name ~short_name ~start_date ~end_date ~public ~status =
    { id; name; short_name; start_date; end_date; public; status; }

end

