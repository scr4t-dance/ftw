
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Artefact

(* Descriptions *)
(* ************************************************************************* *)

module Descr : sig

  include module type of Ftw_core.Artefact.Descr

  val of_toml : Otoml.t -> t

  val to_toml : t -> Otoml.t

end

(* DB Interaction *)
(* ************************************************************************* *)

val p : (int -> 'a, 'a) Sqlite3_utils.Ty.t
(** Sqlite query "type" for identifiers *)

val conv : descr:Descr.t -> t Conv.t
(** Converter for identifiers *)

val get :
  st:State.t ->
  judge:Judge.id ->
  target:Id.t ->
  descr:Descr.t ->
  t

val set :
  st:State.t ->
  judge:Judge.id ->
  target:Id.t ->
  t -> unit

val delete :
  st:State.t ->
  judge:Judge.id ->
  target:Id.t -> unit


(* Serialization *)
(* ************************************************************************* *)

val to_toml : t -> Otoml.t
(** Serialization to toml. *)

val of_toml : descr:Descr.t -> Otoml.t -> t
(** Deserialization from toml.
    @raise Otoml.Type_error *)

module Targeted : sig

  type nonrec t = {
    judge: Judge.id;
    target : Id.t;
    artefact : t;
  }

  val to_toml : t -> Otoml.t
  (** Serialization to toml. *)

  val of_toml : descr:Descr.t -> Otoml.t -> t
  (** Deserialization from toml.
      @raise Otoml.Type_error *)

end
