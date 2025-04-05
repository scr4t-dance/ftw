
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

  type yan_weight = {
      yes : int;
      alt : int;
      no : int;
    } [@@deriving yojson]

  type t =
    | RPSS
    | Yan_weighted of { weights : yan_weight list; }
  [@@deriving yojson]

  (* Algorithms implementations *)
  (* *********************************************************************** *)

  (* TODO *)

end
