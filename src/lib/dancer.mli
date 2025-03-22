


type id = Id.t [@@deriving yojson]
(** Ids for dancers *)

type t = {
  id : id;
  birthday : Date.t option;
  last_name : string;
  first_name : string;
  email : string;
  as_leader : Divisions.t;
  as_follower : Divisions.t;
}
val id : t -> id
val birthday : t -> Date.t option
val last_name : t -> string
val first_name : t -> string
val email : t -> string
val as_leader : t -> Divisions.t
val as_follower : t -> Divisions.t

val conv : t Conv.t
val get : Sqlite3.db -> id -> t
val add :
  Sqlite3.db ->
  Date.t option ->
  last_name:string ->
  first_name:string ->
  email:string -> as_leader:Divisions.t -> as_follower:Divisions.t -> id
  
val update_leader_division : Sqlite3.db -> id -> Divisions.t -> id
val update_follower_division : Sqlite3.db -> id -> Divisions.t -> id
