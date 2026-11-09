
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Serialization *)
(* ************************************************************************* *)

let to_toml i = Otoml.integer i
let of_toml t = Otoml.get_integer t
