
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

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

(* Splitting arrays into segments of given size *)
(* ************************************************************************* *)

module Split = struct

  exception Not_possible

  type split = int list

  type conf =
    | Min_max of { min : int; max: int; }
    | Number of { k : int; }

  let print_conf ?n fmt = function
    | Min_max { min; max; } ->
      Format.fprintf fmt "segments of sizes %d <= .. <= %d" min max
    | Number { k; } ->
      begin match n with
        | None ->
          Format.fprintf fmt "%d segments" k
        | Some n ->
          let m = n / k in
          Format.fprintf fmt "%d segments (with sizes %d <= .. <= %d)"
            k m (m + 1)
      end

  let rec split_min_max_aux ~min ~max n k =
    if k < min then raise Not_possible
    else match split_min_max ~min ~max (n - k) with
      | exception Not_possible -> split_min_max_aux ~min ~max n (k - 1)
      | res -> k :: res

  and split_min_max ~min ~max n =
    if n > max then split_min_max_aux ~min ~max n max
    else if n >= min && n <= max then [n]
    else (assert (n < min); raise Not_possible)

  let split ~conf n =
    try
      match conf with
      | Min_max { min; max; } ->
        Ok (split_min_max ~min ~max n)
      | Number { k; } ->
        let m = n / k in
        Ok (split_min_max ~min:m ~max:(m + 1) n)
    with Not_possible ->
      Error (Format.asprintf
               "Couldn't split array of length %d into %a"
               n (print_conf ~n) conf)

  let apply_to_array ~split:l a =
    let rec aux acc a i = function
      | [] -> assert (i = Array.length a); List.rev acc
      | k :: r ->
        let b = Array.sub a i k in
        aux (b :: acc) a (i + k) r
    in
    aux [] a 0 l

end

(* Randomizer *)
(* ************************************************************************* *)

module Randomizer = struct

  let factor = 2

  let () = Random.self_init ()

  let swap a i j =
    let tmp = a.(i) in
    a.(i) <- a.(j);
    a.(j) <- tmp

  type subst = int array
  (* Fixed-size substitution *)

  let print fmt a =
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
