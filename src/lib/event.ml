
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t

type status =
  | Setup
  | Registration
  | In_progress
  | Finished (**)
(* see the mli for doc *)

type t = {
  id : id;
  (* unique id (among events) *)
  name : string;
  (* main display name for the event *)
  short_name : string;
  (* a short name; currently used when exporting events for the name *)
  start_date : Date.t;
  end_date : Date.t;
  (* start and end dates for the event *)
  public : bool;
  (* whether an event is public and can be seen by anonymous users
     (logged-in users that have a position in the event can always see
     the event regardless of this). *)
  status : status;
  (* current status for the event *)
}

(* Common functions *)
(* ************************************************************************* *)

(* accessors functions *)
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

(* TODO: with the lib/db/api split of the code, this code may not need to
   be "hidden" away anymore *)

module Private = struct

  let with_status status t = { t with status }

  let mk ~id ~name ~short_name ~start_date ~end_date ~public ~status =
    { id; name; short_name; start_date; end_date; public; status; }

end

