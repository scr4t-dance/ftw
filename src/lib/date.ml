
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type & usual functions *)
(* ************************************************************************* *)

type t = {
  day : int;
  month : int;
  year : int;
} [@@deriving yojson]

let compare d d' =
  let open CCOrd in
  int d.year d'.year
  <?> (int, d.month, d'.month)
  <?> (int, d.day, d'.day)

let equal d d' = compare d d' = 0

module Aux = struct
  type nonrec t = t
  let compare = compare
end

module Set = Set.Make(Aux)
module Map = Map.Make(Aux)


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

(*
let month_name t =
  match t.month with
  | 1 -> "Janvier"
  | 2 -> "Février"
  | 3 -> "Mars"
  | 4 -> "Avril"
  | 5 -> "Mai"
  | 6 -> "Juin"
  | 7 -> "Juillet"
  | 8 -> "Août"
  | 9 -> "Septembre"
  | 10 -> "Octobre"
  | 11 -> "Novembre"
  | 12 -> "Décembre"
  | i -> failwith (Format.asprintf "%d is not a valid month" i)
*)

(* DB interactions *)
(* ************************************************************************* *)

let to_string { day; month; year; } =
  Format.asprintf "%04d-%02d-%02d" year month day

let of_string s =
  try
    let year = int_of_string (String.sub s 0 4) in
    let month = int_of_string (String.sub s 5 2) in
    let day = int_of_string (String.sub s 8 2) in
    mk ~day ~month ~year
  with Invalid_argument _ ->
    failwith (Format.asprintf "%s is not a correct date" s)

let p = Sqlite3_utils.Ty.([text])
let conv = Conv.mk p of_string

