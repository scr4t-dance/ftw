
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t

type single = [ `Single ]
type couple = [ `Couple ]
type trouple = [ `Trouple ]

type kind = [ single | couple | trouple ]

type ('kind, 'a) t =
  | Single :
      { target : 'a; role : Role.t; } -> (single, 'a) t
  | Couple :
      { leader : 'a; follower : 'a; } -> (couple, 'a) t
  | Trouple :
      { target1 : 'a; target2 : 'a; target3 : 'a; } -> (trouple, 'a) t

type 'a any = Any : (_, 'a) t -> 'a any
(* Existencial wrappers *)

(* useful alias *)
type ('kind, 'a) target = ('kind, 'a) t


(* Comparison *)
(* ************************************************************************* *)

module Ord(T : Set.OrderedType) :
  Set.OrderedType with type t = T.t any
  = struct
    type t = T.t any
    let compare t t' =
      match t, t' with
      | Any Single { target = t; role = r; },
        Any Single { target = t'; role = r'; } ->
        CCOrd.(Role.compare r r' <?> (T.compare, t, t'))
      | Any Couple { leader = l; follower = f; },
        Any Couple { leader = l'; follower = f'; } ->
        CCOrd.(T.compare l l' <?> (T.compare, f, f'))
      | Any Trouple { target1 = t1; target2 = t2; target3 = t3; },
        Any Trouple { target1 = t1'; target2 = t2'; target3 = t3'; } ->
        CCOrd.(T.compare t1 t1' <?> (T.compare, t2, t2') <?> (T.compare, t3, t3'))
      
      | Any Single _, Any (Couple _ | Trouple _) -> -1
      | Any (Couple _ | Trouple _), Any Single _ -> 1

      | Any Couple _, Any Trouple _ -> -1
      | Any Trouple _, Any Couple _ -> 1
end

(* Creation *)
(* ************************************************************************* *)

let single ~target ~role = Single { target; role; }
let couple ~leader ~follower = Couple { leader; follower; }
let trouple (target1, target2, target3) = Trouple { target1; target2; target3; }

let to_list = function
  | Any Single { target; role; } -> [target, role]
  | Any Couple { leader; follower; } -> [ leader, Leader; follower, Follower]
  | Any Trouple _ ->
    assert false (* TODO add a Role pour trouple dancer and implement this *)


(* Printing *)
(* ************************************************************************* *)

let print_single pp fmt (Single { target; role; }) =
  Format.fprintf fmt "%a:%a" Role.print_compact role pp target

let print_couple pp fmt (Couple { leader; follower; }) =
  Format.fprintf fmt "%a & %a" pp leader pp follower

let print_trouple pp fmt (Trouple {target1; target2; target3; }) =
  Format.fprintf fmt "%a & %a & %a" pp target1 pp target2 pp target3

let print pp fmt = function
  | Any (Single _ as s) -> print_single pp fmt s
  | Any (Couple _ as c) -> print_couple pp fmt c
  | Any (Trouple _ as t) -> print_trouple pp fmt t

(* Mapping over targets *)
(* ************************************************************************* *)

let map (type kind a b) ~f:(f: (a -> b)) (t : (kind, a) t) : (kind, b) t =
  match t with
  | Single { target; role; } ->
    Single { target = f target; role; }
  | Couple { leader; follower; } ->
    Couple { leader = f leader; follower = f follower; }
  | Trouple { target1; target2; target3; } ->
    Trouple { target1 = f target1; target2 = f target2; target3 = f target3; }

let map_any ~f (Any target) = Any (map ~f target)


(* Targets with ids *)
(* ************************************************************************* *)

module With_id = struct

  type ('kind, 'a) t = {
    id : id;
    target : ('kind, 'a) target;
  }

  type 'a any = Any : (_, 'a) t -> 'a any

  let id { id; _ } = id
  let target { target = t; _ } = t

  let mk id target = { id; target; }

end

(* Singles *)
(* ************************************************************************* *)

module Single = struct

  type 'a t = (single, 'a) target

  let role (Single { target = _; role; }) = role
  let dancer (Single { target; role = _; }) = target

  module Ord(T : Set.OrderedType) :
    Set.OrderedType with type t = T.t t
  = struct
    type t = (single, T.t) target
    let compare
        (Single { target = t1; role = r1; })
        (Single { target = t2; role = r2; }) =
      let open CCOrd in
      T.compare t1 t2
      <?> (Role.compare, r1, r2)
  end
end

(* Couples *)
(* ************************************************************************* *)

module Couple = struct

  type 'a t = (couple, 'a) target

  let leader (Couple { leader = t; _ } ) = t
  let follower (Couple { follower = t; _ } ) = t

  module Ord(T : Set.OrderedType) :
    Set.OrderedType with type t = T.t t
  = struct
    type t = (couple, T.t) target
    let compare
        (Couple { leader = l1; follower = f1; })
        (Couple { leader = l2; follower = f2; }) =
      let open CCOrd in
      T.compare l1 l2
      <?> (T.compare, f1, f2)
  end

end

