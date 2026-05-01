
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Basic types/schemas *)
(* ************************************************************************* *)

module Id = struct

  type t = Ftw.Id.t (* = int *)

  let schema : t Schema.t = Schema.mk Jsont.int

end

(* Dates, identifying a day. *)
module Date = struct

  type t = Ftw.Date.t = {
    day : int;
    month : int;
    year : int;
  }

  let day { day; _ } = day
  let month { month; _ } = month
  let year { year; _ } = year
  let make day month year = { day; month; year; }

  let schema : t Schema.t =
    let conv =
      Jsont.Object.map ~kind:"Date" make
      |> Jsont.Object.mem "day" Jsont.int ~enc:day
      |> Jsont.Object.mem "month" Jsont.int ~enc:month
      |> Jsont.Object.mem "year" Jsont.int ~enc:year
      |> Jsont.Object.finish
    in
    Schema.mk conv

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
  }

  let id { id; _ } = id
  let name { name; _ } = name
  let start_date { start_date; _ } = start_date
  let end_date { end_date; _ } = end_date
  let make id name start_date end_date = { id; name; start_date; end_date; }

  let of_ftw ev =
    make
      (Ftw.Event.id ev) (Ftw.Event.name ev)
      (Ftw.Event.start_date ev) (Ftw.Event.end_date ev)

  let schema : t Schema.t =
    let conv =
      Jsont.Object.map ~kind:"Event" make
      |> Jsont.Object.mem "id" (Schema.jsont Id.schema) ~enc:id
      |> Jsont.Object.mem "name" Jsont.string ~enc:name
      |> Jsont.Object.mem "start_date" (Schema.jsont Date.schema) ~enc:start_date
      |> Jsont.Object.mem "end_date" (Schema.jsont Date.schema) ~enc:end_date
      |> Jsont.Object.finish
    in
    Schema.mk conv

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

  type t = Event.t list

  let of_ftw l = List.map Event.of_ftw l

  let schema : t Schema.t =
    let conv = Jsont.list (Schema.jsont Event.schema) in
    Schema.mk conv

end

(* Errors *)
(* ************************************************************************* *)

module Err = struct

  (* TODO: use the proper Error.t type here *)
  type t = string

  let schema : t Schema.t =
    let conv = Jsont.string in
    Schema.mk conv

end
