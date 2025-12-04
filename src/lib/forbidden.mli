type t = { competition : int; dancer1 : int; dancer2 : int; }

val conv : t Conv.t
val get : st:State.t -> competition:int -> t list
val set : st:State.t -> competition:int -> t list -> unit
