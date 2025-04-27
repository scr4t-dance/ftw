
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

module S = Openapi_router.Json_Schema

(* Helper functions *)
(* ************************************************************************* *)

let obj o = S.Obj o
let ref name = S.Ref ("#/components/schemas/" ^ name)

let int = obj S.Integer
let array = obj S.Array
let string = obj S.String
let object_ = obj S.Object

let schemas, make_schema =
  let l = Stdlib.ref [] in
  let schemas router =
    List.fold_left (fun router (name, schema) ->
        Router.schema name (obj schema) router
      ) router !l
  in
  let make_schema ~name
      ?schema ?id_ ?title
      ?description ?default ?examples
      ?read_only ?write_only ?comment
      ?typ ?enum ?const ?multiple_of
      ?minimum ?exclusiveMinimum ?maximum ?exclusiveMaximum
      ?properties ?pattern_properties ?additional_properties ?required
      ?property_names ?min_properties ?max_properties
      ?min_items ?max_items ?items ?prefix_items
      ?format ?pattern ?min_length ?max_length
      ?all_of ?any_of ?one_of
      () =
    let schema =
      S.make_schema ?schema ?id_ ?title
        ?description ?default ?examples
        ?read_only ?write_only ?comment
        ?typ ?enum ?const ?multiple_of
        ?minimum ?exclusiveMinimum ?maximum ?exclusiveMaximum
        ?properties ?pattern_properties ?additional_properties ?required
        ?property_names ?min_properties ?max_properties
        ?min_items ?max_items ?items ?prefix_items
        ?format ?pattern ?min_length ?max_length
        ?all_of ?any_of ?one_of
        ()
    in
    let res = name, schema in
    l := res :: !l;
    res
  in
  schemas, make_schema


(* Common schemas *)
(* ************************************************************************* *)

(* Errors *)
module Error = struct
  type t = {
    message : string;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"Error"
      ~typ:object_
      ~properties:[
        "message", obj @@ S.make_schema ()
          ~typ:string
          (*
          TODO raise issue at openapi_router
          https://swagger.io/docs/specification/v3_0/adding-examples/
          Note that schemas and properties support single example but not multiple examples.
          *)
          (* ~examples:[`String "Event not found"] *)
      ]
end

(* Dates, identifying a day. *)
module Date = struct
  type t = {
    day : int;
    month : int;
    year : int;
  } [@@deriving show, yojson]

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
end

(* Competition Kinds *)
module Kind = struct
  type t = Ftw.Kind.t =
    | Routine
    | Strictly
    | JJ_Strictly
    | Jack_and_Jill
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"Kind"
      ~typ:array
      ~items:(
        obj @@ S.make_schema ()
          ~typ:string
          ~enum:[
            `String "Routine";
            `String "Strictly";
            `String "JJ_Strictly";
            `String "Jack_and_Jill";
          ])
end

(* Competition Division *)
module Division = struct
  type t = Ftw.Division.t =
    | Novice
    | Intermediate
    | Advanced
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"Division"
      ~typ:array
      ~items:(
        obj @@ S.make_schema ()
          ~typ:string
          ~enum:[
            `String "Novice";
            `String "Intermediate";
            `String "Advanced";
          ])
end

(* Dancer Division *)
module Divisions = struct
  type t = Ftw.Divisions.t =
    | None
    | Novice
    | Novice_Intermediate
    | Intermediate
    | Intermediate_Advanced
    | Advanced
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"Divisions"
      ~typ:array
      ~items:(
        obj @@ S.make_schema ()
          ~typ:string
          ~enum:[
            `String "None";
            `String "Novice";
            `String "Novice_Intermediate";
            `String "Intermediate";
            `String "Intermediate_Advanced";
            `String "Advanced";
          ])
end

(* Competition Category *)
module Category = struct
  type t =
    | Novice
    | Intermediate
    | Advanced
    | Regular
    | Qualifying
    | Invited
  [@@deriving yojson]

  let of_ftw cat : t =
    match (cat : Ftw.Category.t) with
    | Competitive Novice -> Novice
    | Competitive Intermediate -> Intermediate
    | Competitive Advanced -> Advanced
    | Non_competitive Regular -> Regular
    | Non_competitive Qualifying -> Qualifying
    | Non_competitive Invited -> Invited

  let to_ftw cat : Ftw.Category.t =
    match cat with
    | Novice -> Competitive Novice
    | Intermediate -> Competitive Intermediate
    | Advanced -> Competitive Advanced
    | Regular -> Non_competitive Regular
    | Qualifying -> Non_competitive Qualifying
    | Invited -> Non_competitive Invited

  let ref, schema =
    make_schema ()
      ~name:"Category"
      ~typ:array
      ~items:(
        obj @@ S.make_schema ()
          ~typ:string
          ~enum:[
            `String "Novice";
            `String "Intermediate";
            `String "Advanced";
            `String "Regular";
            `String "Qualifying";
            `String "Invited";
          ])
end

(* Role *)
module Role = struct
  type t = Ftw.Role.t =
    | Leader
    | Follower
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"Role"
      ~typ:array
      ~items:(
        obj @@ S.make_schema ()
          ~typ:string
          ~enum:[
            `String "Leader";
            `String "Follower";
          ])
end

(* Events *)
(* ************************************************************************* *)

(* Event Ids *)
module EventId = struct
  type t = Ftw.Event.id [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"EventId"
      ~typ:int
      (*
      TODO raise issue at openapi_router
      https://swagger.io/docs/specification/v3_0/adding-examples/
      Note that schemas and properties support single example but not multiple examples.
      *)
      (* ~examples:[`Int 42] *)
end

(* Event Id list *)
module EventIdList = struct
  type t = {
    events : EventId.t list;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"EventIdList"
      ~typ:object_
      ~properties:[
        "events", obj @@ S.make_schema ()
          ~typ:array
          ~items:(ref EventId.ref);
      ]
      ~required:["events"]
end

(* Event specification *)
module Event = struct
  type t = {
    name : string;
    start_date : Date.t;
    end_date : Date.t;
  } [@@deriving yojson]

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
end

(* Competitions *)
(* ************************************************************************* *)

(* Competition Ids *)
module CompetitionId = struct
  type t = Ftw.Competition.id [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"CompetitionId"
      ~typ:int
      (*
      TODO raise issue at openapi_router
      https://swagger.io/docs/specification/v3_0/adding-examples/
      Note that schemas and properties support single example but not multiple examples.
      *)
      (* ~examples:[`Int 42] *)
end

(* Competition Id list *)
module CompetitionIdList = struct
  type t = {
    competitions : CompetitionId.t list;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"CompetitionIdList"
      ~typ:object_
      ~properties:[
        "competitions", obj @@ S.make_schema ()
          ~typ:array
          ~items:(ref CompetitionId.ref);
      ]
      ~required:["competitions"]
end

(* Competition specification *)
module Competition = struct
  type t = {
    event : EventId.t;
    name : string;
    kind : Kind.t;
    category : Category.t;
    leaders_count : int;
    followers_count : int;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"Competition"
      ~typ:(Obj Object)
      ~properties:[
        "event", ref EventId.ref;
        "name", obj @@ S.make_schema ()
          ~typ:string
          (*
          TODO raise issue at openapi_router
          https://swagger.io/docs/specification/v3_0/adding-examples/
          Note that schemas and properties support single example but not multiple examples.
          *)
        (* ~examples:[`String "P4T"]*) ;
        "kind", ref Kind.ref;
        "category", ref Category.ref;
        "leaders_count", obj @@ S.make_schema () ~typ:int;
        "followers_count", obj @@ S.make_schema () ~typ:int;
      ]
      ~required:["event"; "name"; "kind"; "category"; "leaders_count"; "followers_count"]
end



(* Dancers *)
(* ************************************************************************* *)

(* Dancer Ids *)
module DancerId = struct
  type t = Ftw.Dancer.id [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"DancerId"
      ~typ:int
      (*
      TODO raise issue at openapi_router
      https://swagger.io/docs/specification/v3_0/adding-examples/
      Note that schemas and properties support single example but not multiple examples.
      *)
      (* ~examples:[`Int 42] *)
end

(* Dancer Id list *)
module DancerIdList = struct
  type t = {
    dancers : DancerId.t list;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"DancerIdList"
      ~typ:object_
      ~properties:[
        "dancers", obj @@ S.make_schema ()
          ~typ:array
          ~items:(ref DancerId.ref);
      ]
      ~required:["dancers"]
end

(* Dancer specification *)
module Dancer = struct
  type t = {
    birthday : Date.t option;
    last_name : string;
    first_name : string;
    email : string option;
    as_leader : Divisions.t;
    as_follower : Divisions.t;
  } [@@deriving yojson { strict = false }]

  let ref, schema =
    make_schema ()
      ~name:"Dancer"
      ~typ:(Obj Object)
      ~properties:[
        "birthday", ref Date.ref;
        "last_name", obj @@ S.make_schema ()
          ~typ:string;
        "first_name", obj @@ S.make_schema ()
          ~typ:string;
        "email", obj @@ S.make_schema ()
          ~typ:string;
        "as_leader", ref Divisions.ref;
        "as_follower", ref Divisions.ref;
      ]
      ~required:["last_name"; "first_name"; "as_leader"; "as_follower"]
end

(* Bibs *)
(* ************************************************************************* *)


module SingleTarget = struct
  type t = {
    target_type: string;
    target : DancerId.t;
    role : Role.t;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"SingleTarget"
      ~typ:object_
      ~properties:[
        "target_type", obj @@ S.make_schema()
          ~typ:string
          ~enum:[`String "single"];
        "target", ref DancerId.ref;
        "role", ref Role.ref;
      ]
      ~required:["target_type"; "target"; "role"]
end


module CoupleTarget = struct
  type t = {
    target_type: string;
    leader : DancerId.t;
    follower : DancerId.t;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"CoupleTarget"
      ~typ:object_
      ~properties:[
        "target_type", obj @@ S.make_schema()
          ~typ:string
          ~enum:[`String "couple"];
        "leader", ref DancerId.ref;
        "follower", ref DancerId.ref;
      ]
      ~required:["target_type"; "leader"; "follower"]
end

module Target = struct
  type t =
    | TargetSingle of {target: SingleTarget.t}
    | TargetCouple of {target: CoupleTarget.t}
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"Target"
      ~typ:object_
      ~one_of:[
        (ref SingleTarget.ref);
        (ref CoupleTarget.ref);
      ]


  let dancers target =
    match target with
    | TargetSingle {target=s} -> [s.target]
    | TargetCouple {target=s} -> [s.leader;s.follower]

  let of_ftw s =
    match s with
    | Ftw.Bib.Any (Single {target;role}) -> TargetSingle {target={target;role;target_type="single"}}
    | Ftw.Bib.Any (Couple {leader;follower}) -> TargetCouple {target={leader;follower;target_type="couple"}}

  let to_ftw s =
    match s with
    | TargetSingle {target={target;role; _}} -> Ftw.Bib.Any (Single {target;role})
    | TargetCouple {target={leader;follower; _}} -> Ftw.Bib.Any (Couple {leader;follower})


  let to_yojson target =
    match target with
    | TargetSingle {target=t} ->
      let schema_fields =
        begin match SingleTarget.to_yojson t with
          | `Assoc fields -> fields
          | _ -> failwith "Expected schema to serialize to an object"
        end
      in
      `Assoc ([("target_type", `String "single");] @ schema_fields)
    | TargetCouple {target=t} ->
      let schema_fields =
        begin match CoupleTarget.to_yojson t with
          | `Assoc fields -> fields
          | _ -> failwith "Expected schema to serialize to an object"
        end
      in
      `Assoc ([("target_type", `String "couple");] @ schema_fields)

  let of_yojson json =
    match json with
    | `Assoc fields -> (
        match List.assoc_opt "target_type" fields with
        | Some (`String "single") -> SingleTarget.of_yojson json |> Result.map (fun s -> TargetSingle {target=s})
        | Some (`String "couple") -> CoupleTarget.of_yojson json |> Result.map (fun s -> TargetCouple {target=s})
        | Some (`String unknown) -> Error ("Unrecognised target_type: " ^ unknown)
        | Some _  -> Error ("Unrecognised target_type")
        | None -> Error "Missing key: target_type"
      )
    | _ -> Error "Expected JSON object for Target"
end

module Bib = struct

  type t = {
    competition : CompetitionId.t;
    bib : int;
    target : Target.t;
  } [@@deriving yojson]


  let ref, schema =
    make_schema ()
      ~name:"Bib"
      ~typ:(Obj Object)
      ~properties:[
        "competition", ref CompetitionId.ref;
        "bib", obj @@ S.make_schema()
          ~typ:int;
        "target", ref Target.ref;
      ]
      ~required:["competition"; "bib"; "target"]

end

(* BibSingle list *)
module BibList = struct
  type t = {
    bibs : Bib.t list;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"BibList"
      ~typ:object_
      ~properties:[
        "bibs", obj @@ S.make_schema ()
          ~typ:array
          ~items:(ref Bib.ref);
      ]
      ~required:["bibs"]

end
