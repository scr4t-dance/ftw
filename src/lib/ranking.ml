
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type description *)
(* ************************************************************************* *)

(*
type 'a t = 'a Target.t array array
type 'a ranking = 'a t (* alias for use later in this file *)


type 'a rank =
  | Ranked of 'a Target.t
  | Tie of {
      rank : int;
      tie : 'a Target.t array;
    }
*)

(* Access functions *)
(* ************************************************************************* *)


(* Algorithms for creating rankings *)
(* ************************************************************************* *)

module Algorithm = struct

  module YanWeight = struct
    
    type t = {
      yes : int;
      alt : int;
      no : int;
    } [@@deriving yojson]

    let of_string s = match String.split_on_char ',' s with
      | [yes; alt; no] -> {yes=int_of_string yes; alt=int_of_string alt; no=int_of_string no}
      | _ -> raise (Invalid_argument ("Invalid YanWeigth type: " ^ s))

    let to_string yw = String.concat "," @@ List.map string_of_int [yw.yes; yw.alt; yw.no]
  end

  type t =
    | RPSS
    | Yan_weighted of { weights : YanWeight.t list; }
  [@@deriving yojson]

  let of_string s =
    match s with
    | "RPSS" -> RPSS
    | _ -> match CCString.chop_prefix ~pre:"yan_weights:" s with
      | Some criterion_list -> Yan_weighted { 
          weights = List.map YanWeight.of_string 
            (String.split_on_char ';' criterion_list)
        }
      | None -> raise (Invalid_argument ("Invalid t type: " ^ s))

  let to_string = function
    | RPSS -> "RPSS"
    | Yan_weighted { weights } -> 
        "yan_weights:" ^ String.concat ";" (List.map YanWeight.to_string weights)

  (* Algorithms implementations *)
  (* *********************************************************************** *)

  (* TODO *)

end
