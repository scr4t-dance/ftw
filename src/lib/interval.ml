
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Interval maps *)
(* ************************************************************************* *)

module Map = struct

  module type Arg = sig
    type t
    val compare : t -> t -> int
    val print : Format.formatter -> t -> unit
  end

  module type S = sig

    type key
    type 'a t

    val of_list : (key * 'a) list -> 'a t

    val find_exn : 'a t -> key -> 'a

    val find_opt : 'a t -> key -> 'a option

  end

  module Make(K : Arg) : S with type key = K.t = struct

    module M = Map.Make(K)

    type key = K.t

    type 'a t = 'a M.t

    let find_exn t k =
      let _, res = M.find_last (fun k' -> K.compare k k' >= 0) t in
      res

    let find_opt t k =
      try Some (find_exn t k)
      with Not_found -> None

    let of_list l =
      List.fold_left (fun acc (k, v) -> M.add k v acc) M.empty l

  end

end
