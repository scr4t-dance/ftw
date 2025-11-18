
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Result monadic operators *)
(* ************************************************************************* *)

module Opt = struct

  let (let+) = Option.bind

end

module Result = struct

  let (let+) = Result.bind

end

(* Common Errors *)
(* ************************************************************************* *)

module Error = struct

  exception Deserialization_error of {
      payload : string;
      expected : string;
    }

  let deserialization ~payload ~expected =
    raise (Deserialization_error { payload; expected; })

end

(* Lists *)
(* ************************************************************************* *)

module Lists = struct

  let all_the_same ~eq = function
    | [] -> None
    | h :: r -> if List.for_all (eq h) r then Some h else None

end

(* Matrix *)
(* ************************************************************************* *)

module Matrix = struct

  let (++) a b =
    assert (Array.length a = Array.length b);
    Array.map2 Array.append a b

end

(* Bitwise manipulations *)
(* ************************************************************************* *)

module Bit = struct

  let[@inline] set ~index i =
    i lor (1 lsl index)

  let[@inline] is_set ~index i =
    assert (0 <= index && index <= 60);
    let mask = 1 lsl index in
    i land mask <> 0

end

(* Json helpers *)
(* ************************************************************************* *)

module Json = struct

  let print ~to_yojson value =
    Yojson.Safe.to_string (to_yojson value)

  let parse ~of_yojson s =
    try of_yojson (Yojson.Safe.from_string s)
    with Yojson.Json_error msg -> Error msg

  let parse_exn ~of_yojson s =
    match parse ~of_yojson s with
    | Ok res -> res
    | Error msg -> failwith ("Misc.Json.parse_exn: " ^ msg)

end

(* Toml helpers *)
(* ************************************************************************* *)

module Toml = struct

  let add name f x l =
    (name, f x) :: l

  let add_opt name f o l =
    match o with
    | None -> l
    | Some x -> add name f x l

end

module Split = struct

  let rec split_aux ~min ~max n k =
    if k < min then raise Exit
    else match split ~min ~max (n - k) with
      | exception Exit -> split_aux ~min ~max n (k - 1)
      | res -> k :: res

  and split ~min ~max n =
    if n > max then split_aux ~min ~max n max
    else if n >= min && n <= max then [n]
    else (assert (n < min); raise Exit)

  let rec split_array_aux acc a i = function
    | [] -> assert (i = Array.length a); List.rev acc
    | k :: r ->
      let b = Array.sub a i k in
      split_array_aux (b :: acc) a (i + k) r

  let split_array ~min ~max a =
    let n = Array.length a in
    match split ~min ~max n with
    | l ->
      let l = split_array_aux [] a 0 l in
      Array.of_list l
    | exception Exit ->
      failwith (Format.asprintf
                  "Couldn't split the list of participants (n = %d) into pools (%d/%d)"
                  n min max)

end

module Randomizer = struct

  let factor = 2

  let () = Random.self_init ()

  let swap a i j =
    let tmp = a.(i) in
    a.(i) <- a.(j);
    a.(j) <- tmp

  type subst = int array
  (* Fixed-size substitution *)

  let pp fmt a =
    let l = Array.to_list a in
    let pp_sep fmt () = Format.fprintf fmt ";@ " in
    Format.fprintf fmt "@[<hov 1>[%a]@]"
      (Format.pp_print_list ~pp_sep Format.pp_print_int) l

  let id n =
    Array.init n (fun i -> i)

  let inverse s =
    let s' = Array.make (Array.length s) ~-1 in
    Array.iteri (fun i j -> s'.(j) <- i) s;
    s'

  let apply s a =
    let s' = inverse s in
    Array.init (Array.length a) (fun i -> a.(s'.(i)))

  let randomize_in_place s =
    let n = Array.length s in
    for _ = 1 to factor * n do
      let i = Random.int n in
      let j = Random.int n in
      swap s i j
    done

  (* TODO: keep a set of already tried substs in order to ensure
           termination ? *)
  let subst ?(check=(fun _ -> true)) n =
    let s = id n in
    let test = ref false in
    while not !test do
      randomize_in_place s;
      test := check s
    done;
    s

  let not_id s =
    try
      Array.iteri (fun i j ->
          if i <> j then raise Exit) s;
      false
    with Exit -> true

  let all_different s s' =
    try
      Array.iter2 (fun i j ->
          if i = j then raise Exit) s s';
      true
    with Exit -> false

  let no_fixpoint s =
    try
      Array.iteri (fun i j ->
          if i = j then raise Exit) s;
      true
    with Exit -> false

end
