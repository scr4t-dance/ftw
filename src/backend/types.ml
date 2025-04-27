
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

(* Ok/Unit: i.e. no meaningful return value (apart from the HTPP return code) *)
module Ok = struct
  type t = unit [@@deriving yojson]

  (* TODO: how to specify NULL as a JSON schema ? *)
  let ref, schema =
    make_schema ()
      ~name:"Ok"
      ~typ:(obj S.Null)

end

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
          ]
      )
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
          ]
      )
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
          ]
      )
end

(* Round *)
module Round = struct
  type t = Ftw.Round.t =
    | Prelims
    | Octofinals
    | Quarterfinals
    | Semifinals
    | Finals
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"Round"
      ~typ:array
      ~items:(
        obj @@ S.make_schema ()
          ~typ:string
          ~enum:[
            `String "Prelims";
            `String "Octofinals";
            `String "Quarterfinals";
            `String "Semifinals";
            `String "Finals";
          ]
      )
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
          ]
      )
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
    n_leaders : int;
    n_follows : int;
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
        "n_leaders", obj @@ S.make_schema () ~typ:int;
        "n_follows", obj @@ S.make_schema () ~typ:int;
      ]
end

(* Artefact *)
(* ************************************************************************* *)

module YanCriterionWeights = struct
  type t = Ftw.Ranking.Algorithm.yan_weight [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"YanCriterionWeights"
      ~typ:(Obj Object)
      ~properties:[
        "yes", obj @@ S.make_schema ()
          ~typ:int;
        "alt", obj @@ S.make_schema ()
          ~typ:int;
        "no", obj @@ S.make_schema ()
          ~typ:int;
      ]
end

module RankingYanWeighted = struct
  type t = {
    weights: YanCriterionWeights.t list;
    head_weights: YanCriterionWeights.t list;
  }
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"RankingYanWeighted"
      ~typ:array
      ~description: {| Ranking algorithm for Yan_weighted |}
      ~items:(ref YanCriterionWeights.ref)

  let of_ftw criterion_weights =
    match criterion_weights with
    | Ftw.Ranking.Algorithm.Yan_weighted { weights; head_weights} ->
      {weights=weights;head_weights=head_weights;}
    | _ -> assert false

  let to_ftw {weights;head_weights;} =
    Ftw.Ranking.Algorithm.Yan_weighted {weights=weights;head_weights=head_weights}
end


module RankingAlgorithm = struct

  let src = Logs.Src.create "backend.types.RkgAlgo"

  type t = Ftw.Ranking.Algorithm.t =
    | RPSS
    | Yan_weighted of {
        weights : YanCriterionWeights.t list;
        head_weights : YanCriterionWeights.t list;
      }
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"RankingAlgorithm"
      ~description: {| algorithm is either ranking or yan.
        For a ranking algorithm, ranking_algorithm property should be specified.
        For a Yan_weighted algorithm, weights and head_weights properties should be set. |}
      ~typ:(Obj Object)
      ~properties:[
        "algorithm", obj @@ S.make_schema ()
          ~typ:string
          ~examples:[`String "Yan_weighted"; `String "RPSS"];
        "algorithm_data", obj @@ S.make_schema ()
          ~one_of:[
            obj @@ S.make_schema ()
              ~typ:array
              ~items:(ref YanCriterionWeights.ref);
            obj @@ S.make_schema ()
              ~typ:(obj S.Null)
          ]
      ]



  let of_yojson json =
    Logs.debug ~src (fun k->
        k "@[<hv 2> Parsing '%s'" (Yojson.Safe.pretty_to_string json)
      );
    let open Yojson.Safe.Util in
    match json with
    | `Assoc _ ->
      let algo = json |> member "algorithm" |> to_string in
      let data = json |> member "algorithm_data" in
      begin match algo with
        | "Yan_weighted" ->
          let weights = data |> member "weights" |> to_list in
          let head_weights = data |> member "head_weights" |> to_list in

          let sequence (lst : ('a, 'e) result list) : ('a list, 'e) result =
            List.fold_right
              (fun res acc ->
                 match res, acc with
                 | Ok x, Ok xs -> Ok (x :: xs)
                 | Error e, _ -> Error e
                 | _, Error e -> Error e)
              lst (Ok [])
          in
          let weights = sequence (List.map YanCriterionWeights.of_yojson weights) in
          let head_weights = sequence (List.map YanCriterionWeights.of_yojson head_weights) in

          begin match weights, head_weights with
            | Ok w, Ok hw -> Ok (Yan_weighted { weights=w; head_weights=hw })
            | Error e, Ok _ -> Error e
            | Ok _, Error e -> Error e
            | Error w_e, Error _ -> Error w_e
          end

        | "RPSS" -> Ok RPSS

        | other ->
          Error ("Unknown algorithm: " ^ other)
      end
    | _ -> Error "Expected JSON object"

  let to_yojson algorithm =
    match algorithm with
    | Yan_weighted {weights; head_weights} ->
      `Assoc [
        ("algorithm", `String "yan");
        ("algorithm_data", `Assoc [
            ("weights", `List (List.map YanCriterionWeights.to_yojson weights));
            ("head_weights", `List (List.map YanCriterionWeights.to_yojson head_weights));
          ]
        );
      ]
    | RPSS ->
      `Assoc [
        ("algorithm", `String "RPSS");
        ("algorithm_data", `Null);
      ]

end

module ArtefactDescription = struct

  let src = Logs.Src.create "backend.types.ArtfDescr"

  type t = Ftw.Artefact.Descr.t =
    | Ranking
    | Yans of { criterion : string list; }
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"ArtefactDescription"
      ~description: {| artefact is either ranking or yan.
        For a ranking artefact, ranking_algorithm property should be specified.
        For a yan artefact, yan_criterion property should be set. |}
      ~typ:(Obj Object)
      ~properties:[
        "artefact", obj @@ S.make_schema ()
          ~typ:string
          ~examples:[`String "yan"; `String "ranking"];
        "artefact_data", obj @@ S.make_schema ()
          ~one_of:[
            obj @@ S.make_schema ()
              ~typ:array
              ~items:(
                obj @@ S.make_schema ()
                  ~typ:string
              );
            obj @@ S.make_schema ()
              ~typ:(obj S.Null)
          ]
      ]


  let of_yojson json =
    Logs.debug ~src (fun k->
        k "@[<hv 2> Parsing '%s'" (Yojson.Safe.pretty_to_string json)
      );
    let open Yojson.Safe.Util in
    let artefact = json |> member "artefact" |> to_string in
    match artefact with
    | "yan" ->
      let criterion = json |> member "artefact_data" |> to_list |> List.map to_string in
      Ok (Yans { criterion })
    | "ranking" ->
      let data = json |> member "artefact_data" in
      if data = `Null then Ok Ranking else Error "artefact_data expected to be null for RPSS"
    | other ->
      Error ("Unknown artefact type: " ^ other)

  let to_yojson artefact =
    match artefact with
    | Yans {criterion} ->
      `Assoc [
        ("artefact", `String "yan");
        ("artefact_data", `List (List.map (fun s -> `String s) criterion));
      ]

    | Ranking ->
      `Assoc [
        ("artefact", `String "ranking");
        ("artefact_data", `Null);
      ]

end


(* Phases *)
(* ************************************************************************* *)

(* Phase Ids *)
module PhaseId = struct
  type t = Ftw.Phase.id [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"PhaseId"
      ~typ:int
      ~examples:[`Int 42]
end

(* Phase Id list *)
module PhaseIdList = struct
  type t = {
    phases : PhaseId.t list;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"PhaseIdList"
      ~typ:object_
      ~properties:[
        "phases", obj @@ S.make_schema ()
          ~typ:array
          ~items:(ref PhaseId.ref);
      ]
end

(* Phase specification *)
module Phase = struct
  type t = {
    competition : CompetitionId.t;
    round : Round.t;
    judge_artefact_descr : ArtefactDescription.t;
    head_judge_artefact_descr : ArtefactDescription.t;
    ranking_algorithm: RankingAlgorithm.t;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"Phase"
      ~typ:(Obj Object)
      ~properties:[
        "competition", ref CompetitionId.ref;
        "round", ref Round.ref;
        "judge_artefact_descr", ref ArtefactDescription.ref;
        "head_judge_artefact_descr", ref ArtefactDescription.ref;
        "ranking_algorithm", ref RankingAlgorithm.ref;
      ]

end


(* Heats *)
(* ************************************************************************* *)

(* Heat Ids *)
module HeatId = struct
  type t = Ftw.Heat.target_id [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"HeatId"
      ~typ:int
      ~examples:[`Int 42]
end

(* Heat Id list *)
module HeatIdList = struct
  type t = {
    phases : HeatId.t list;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"HeatIdList"
      ~typ:object_
      ~properties:[
        "heats", obj @@ S.make_schema ()
          ~typ:array
          ~items:(ref HeatId.ref);
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
    birthday : Date.t option [@default None];
    last_name : string;
    first_name : string;
    email : string option [@default None];
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
