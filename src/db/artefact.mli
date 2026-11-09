
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Descriptions *)
(* ************************************************************************* *)

module Descr : sig

  val of_toml : Otoml.t -> Lib.Artefact.Descr.t

  val to_toml : Lib.Artefact.Descr.t -> Otoml.t

end

(* DB Interaction *)
(* ************************************************************************* *)

val p : (int -> 'a, 'a) Sqlite3_utils.Ty.t
(** Sqlite query "type" for identifiers *)

val conv : descr:Lib.Artefact.Descr.t -> Lib.Artefact.t Conv.t
(** Converter for identifiers *)

val get :
  st:State.t ->
  judge:Lib.Judge.id ->
  target:Lib.Id.t ->
  descr:Lib.Artefact.Descr.t ->
  Lib.Artefact.t

val set :
  st:State.t ->
  judge:Lib.Judge.id ->
  target:Lib.Id.t ->
  Lib.Artefact.t -> unit

val delete :
  st:State.t ->
  judge:Lib.Judge.id ->
  target:Lib.Id.t -> unit

val clear :
    st:State.t ->
    judge:Lib.Judge.id ->
    phase:Lib.Phase.id -> unit


(* Serialization *)
(* ************************************************************************* *)

val to_toml : Lib.Artefact.t -> Otoml.t
(** Serialization to toml. *)

val of_toml : descr:Lib.Artefact.Descr.t -> Otoml.t -> Lib.Artefact.t
(** Deserialization from toml.
    @raise Otoml.Type_error *)

module Targeted : sig

  type nonrec t = {
    judge: Lib.Judge.id;
    target : Lib.Id.t;
    artefact : Lib.Artefact.t;
  }

  val to_toml : t -> Otoml.t
  (** Serialization to toml. *)

  val of_toml : descr:Lib.Artefact.Descr.t -> Otoml.t -> t
  (** Deserialization from toml.
      @raise Otoml.Type_error *)

end
