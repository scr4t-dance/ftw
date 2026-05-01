
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Sexplib0.Sexp_conv
open Ppx_compare_lib.Builtin

(* Basic types/schemas *)
(* ************************************************************************* *)

module Id = struct

  type t = Ftw.Id.t (* = int *)

  let schema : t Schema.t =
    Schema.mk
      ~jsont:Jsont.int
      ~equal:Ftw.Id.equal
      ~t_of_sexp:int_of_sexp
      ~sexp_of_t:sexp_of_int

end

(* Dates, identifying a day. *)
module Date = struct

  type t = Ftw.Date.t = {
    day : int;
    month : int;
    year : int;
  } [@@deriving sexp, equal]

  let day { day; _ } = day
  let month { month; _ } = month
  let year { year; _ } = year
  let make day month year = { day; month; year; }

  let jsont =
    Jsont.Object.map ~kind:"Date" make
    |> Jsont.Object.mem "day" Jsont.int ~enc:day
    |> Jsont.Object.mem "month" Jsont.int ~enc:month
    |> Jsont.Object.mem "year" Jsont.int ~enc:year
    |> Jsont.Object.finish

  let schema : t Schema.t =
    Schema.mk ~jsont ~equal ~sexp_of_t ~t_of_sexp

  (* OpenAPI spec
  let ref, schema =
    make_schema ()
      ~name:"Date"
      ~typ:object_
      ~required:["year";"month";"day"]
      ~properties:[
        "day", obj @@ S.make_schema ()
          ~typ:int
          (*
          TODO raise issue at openapi_router
          https://swagger.io/docs/specification/v3_0/adding-examples/
          Note that schemas and properties support single example but not multiple examples.
          *)
        (* ~examples:[`Int 1; `Int 31] *);
        "month", obj @@ S.make_schema ()
          ~typ:int
        (* ~examples:[`Int 1; `Int 12] *);
        "year", obj @@ S.make_schema ()
          ~typ:int
        (* ~examples:[`Int 2019; `Int 2024] *);
      ]
    *)
end


(* Common types/schemas *)
(* ************************************************************************* *)

module Event = struct

  type t = {
    id : int;
    name : string;
    start_date : Date.t;
    end_date : Date.t;
  } [@@deriving sexp, equal]

  let id { id; _ } = id
  let name { name; _ } = name
  let start_date { start_date; _ } = start_date
  let end_date { end_date; _ } = end_date
  let make id name start_date end_date = { id; name; start_date; end_date; }

  let of_ftw ev =
    make
      (Ftw.Event.id ev) (Ftw.Event.name ev)
      (Ftw.Event.start_date ev) (Ftw.Event.end_date ev)

  let jsont =
    Jsont.Object.map ~kind:"Event" make
    |> Jsont.Object.mem "id" (Schema.jsont Id.schema) ~enc:id
    |> Jsont.Object.mem "name" Jsont.string ~enc:name
    |> Jsont.Object.mem "start_date" (Schema.jsont Date.schema) ~enc:start_date
    |> Jsont.Object.mem "end_date" (Schema.jsont Date.schema) ~enc:end_date
    |> Jsont.Object.finish

  let schema : t Schema.t =
    Schema.mk ~equal ~jsont ~t_of_sexp ~sexp_of_t

  (* OpenAPI spec
  let ref, schema =
    make_schema ()
      ~name:"Event"
      ~typ:(Obj Object)
      ~properties:[
        "name", obj @@ S.make_schema ()
          ~typ:string
          (*
          TODO raise issue at openapi_router
          https://swagger.io/docs/specification/v3_0/adding-examples/
          Note that schemas and properties support single example but not multiple examples.
          *)
        (* ~examples:[`String "P4T"] *);
        "start_date", ref Date.ref;
        "end_date", ref Date.ref;
      ]
      ~required:["name"; "start_date"; "end_date"]
  *)

end

module EventList = struct

  type t = Event.t list [@@deriving sexp, equal]

  let of_ftw l = List.map Event.of_ftw l

  let jsont = Jsont.list (Schema.jsont Event.schema)

  let schema : t Schema.t =
    Schema.mk ~equal ~jsont ~t_of_sexp ~sexp_of_t

end

(* Errors *)
(* ************************************************************************* *)

module Err = struct

  (* TODO: use the proper Error.t type here *)
  type t = string [@@deriving sexp, equal]

  let jsont = Jsont.string

  let schema : t Schema.t =
    Schema.mk ~equal ~jsont ~t_of_sexp ~sexp_of_t

end
