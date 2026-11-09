
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definition *)
(* ************************************************************************* *)

type t = {
  day : int;
  month : int;
  year : int;
}


(* Helper functions *)
(* ************************************************************************* *)

let day { day; _ } = day
let month { month; _ } = month
let year { year; _ } = year

exception Invalid_date of [`Day | `Month]

let mk ~day ~month ~year =
  if day <= 0 || day > 31 then raise (Invalid_date `Day);
  if month <= 0 || month > 12 then raise (Invalid_date `Month);
  { day; month; year; }

let first_day ~year = mk ~day:1 ~month:1 ~year
let last_day ~year = mk ~day:31 ~month:12 ~year

(* Usual functions *)
(* ************************************************************************* *)

let print fmt { day; month; year; } =
  Format.fprintf fmt "%02d/%02d/%04d" day month year

let compare d d' =
  let open CCOrd in
  int d.year d'.year
  <?> (int, d.month, d'.month)
  <?> (int, d.day, d'.day)

let equal d d' = compare d d' = 0

module Aux = struct
  type nonrec t = t
  let print = print
  let compare = compare
end

module Set = Set.Make(Aux)
module Map = Map.Make(Aux)
module Itm = Interval.Map.Make(Aux)


