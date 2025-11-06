
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

let boolean = obj S.Boolean

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
  type t = Ftw.Date.t = {
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
      ~required:["event"; "name"; "kind"; "category"; "n_leaders"; "n_follows"]
end

(* Artefact *)
(* ************************************************************************* *)

module YanCriterionWeights = struct
  type t = Ftw.Ranking.Yan_weighted.weight [@@deriving yojson]

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
      ~required:["yes"; "alt"; "no"]
end

module RankingAlgorithmYanWeighted = struct
  type t = {
    algorithm: string;
    weights: YanCriterionWeights.t list;
    head_weights: YanCriterionWeights.t list;
  }
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"RankingYanWeighted"
      ~typ:(Obj Object)
      ~properties:[
        "algorithm", obj @@ S.make_schema ()
          ~typ:string
          ~enum:[`String "Yan_weighted"];
        "weights", obj @@ S.make_schema ()
          ~typ:array
          ~description: {| Ranking algorithm for Yan_weighted |}
          ~items:(ref YanCriterionWeights.ref);
        "head_weights", obj @@ S.make_schema ()
          ~typ:array
          ~description: {| Ranking algorithm for Yan_weighted |}
          ~items:(ref YanCriterionWeights.ref);
      ]
      ~required:["weights"; "head_weights"]


  let of_ftw criterion_weights =
    match criterion_weights with
    | Ftw.Ranking.Algorithm.Yan_weighted { weights; head_weights} ->
      {algorithm="Yan_weighted";weights=weights;head_weights=head_weights;}
    | _ -> assert false

  let to_ftw {weights;head_weights;_} =
    Ftw.Ranking.Algorithm.Yan_weighted {weights=weights;head_weights=head_weights}
end

module RankingAlgorithmRanking = struct

  let src = Logs.Src.create "backend.types.ArtfDescr"

  type t = {
    algorithm: string;
    algorithm_name: string;
  }
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"RankingAlgorithmRanking"
      ~description: {| artefact is either ranking or yan. |}
      ~typ:(Obj Object)
      ~properties:[
        "algorithm", obj @@ S.make_schema ()
          ~typ:string
          ~enum:[`String "ranking"];
        "algorithm_name", obj @@ S.make_schema ()
          ~typ:string
          ~enum:[`String "RPSS"];
      ]
      ~required:["algorithm"; "algorithm_name"]

end


module RankingAlgorithm = struct
  type t =
    | Yan_weighted of {algorithm: RankingAlgorithmYanWeighted.t}
    | Ranking of {algorithm: RankingAlgorithmRanking.t}
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"RankingAlgorithm"
      ~typ:object_
      ~one_of:[
        (ref RankingAlgorithmYanWeighted.ref);
        (ref RankingAlgorithmRanking.ref);
      ]
      ~required:["algorithm"]

  let of_ftw s =
    match s with
    | Ftw.Ranking.Algorithm.Yan_weighted {weights;head_weights} -> Yan_weighted {algorithm={algorithm="Yan_weighted";weights=weights;head_weights=head_weights}}
    | Ftw.Ranking.Algorithm.RPSS () -> Ranking {algorithm={algorithm="ranking";algorithm_name="RPSS"}}

  let to_ftw s =
    match s with
    | Yan_weighted {algorithm={weights;head_weights; _}} -> Ftw.Ranking.Algorithm.Yan_weighted {weights;head_weights}
    | Ranking {algorithm={algorithm_name="RPSS";_}} -> Ftw.Ranking.Algorithm.RPSS ()
    | Ranking {algorithm=_} -> Ftw.Ranking.Algorithm.RPSS ()


  let to_yojson target =
    match target with
    | Yan_weighted {algorithm=t} ->
      let schema_fields =
        begin match RankingAlgorithmYanWeighted.to_yojson t with
          | `Assoc fields -> fields
          | _ -> failwith "Expected schema to serialize to an object"
        end
      in
      `Assoc schema_fields
    | Ranking {algorithm=t} ->
      let schema_fields =
        begin match RankingAlgorithmRanking.to_yojson t with
          | `Assoc fields -> fields
          | _ -> failwith "Expected schema to serialize to an object"
        end
      in
      `Assoc schema_fields

  let of_yojson json =
    match json with
    | `Assoc fields -> (
        match List.assoc_opt "algorithm" fields with
        | Some (`String "Yan_weighted") -> RankingAlgorithmYanWeighted.of_yojson json |> Result.map (fun s -> Yan_weighted {algorithm=s})
        | Some (`String "ranking") -> RankingAlgorithmRanking.of_yojson json |> Result.map (fun s -> Ranking {algorithm=s})
        | Some (`String unknown) -> Error ("Unrecognised algorithm: " ^ unknown)
        | Some _  -> Error ("Unrecognised algorithm")
        | None -> Error "Missing key: algorithm"
      )
    | _ -> Error "Expected JSON object for ArtefactDescription"
end


(* Artefact Description *)
(* *************************************************************** *)

module ArtefactDescriptionYans = struct

  let src = Logs.Src.create "backend.types.ArtfDescr"

  type t = {
    artefact: string;
    artefact_data: string list;
  }
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"ArtefactDescriptionYans"
      ~description: {| artefact is either ranking or yan. |}
      ~typ:(Obj Object)
      ~properties:[
        "artefact", obj @@ S.make_schema ()
          ~typ:string
          ~enum:[`String "yan";];
        "artefact_data", obj @@ S.make_schema ()
          ~typ:array
          ~items:(
            obj @@ S.make_schema ()
              ~typ:string
          );
      ]
      ~required:["artefact"; "artefact_data"]


end


module ArtefactDescriptionRanking = struct

  let src = Logs.Src.create "backend.types.ArtfDescr"

  type t = {
    artefact: string;
    artefact_data: unit;
  }
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"ArtefactDescriptionRanking"
      ~description: {| artefact is either ranking or yan. |}
      ~typ:(Obj Object)
      ~properties:[
        "artefact", obj @@ S.make_schema ()
          ~typ:string
          ~enum:[`String "ranking"];
        "artefact_data", obj @@ S.make_schema ()
          ~typ:(obj S.Null)

      ]
      ~required:["artefact"; "artefact_data"]

end

module ArtefactDescription = struct
  type t =
    | YanArtefact of {description: ArtefactDescriptionYans.t}
    | RankingArtefact of {description: ArtefactDescriptionRanking.t}
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"ArtefactDescription"
      ~typ:object_
      ~one_of:[
        (ref ArtefactDescriptionYans.ref);
        (ref ArtefactDescriptionRanking.ref);
      ]
      ~required:["artefact"; "artefact_data"]

  let of_ftw s =
    match s with
    | Ftw.Artefact.Descr.Yans {criterion;} -> YanArtefact {description={artefact="yan";artefact_data=criterion}}
    | Ftw.Artefact.Descr.Ranking -> RankingArtefact {description={artefact="ranking";artefact_data=()}}

  let to_ftw s =
    match s with
    | YanArtefact {description={artefact_data; _}} -> Ftw.Artefact.Descr.Yans {criterion=artefact_data;}
    | RankingArtefact {description=_} -> Ftw.Artefact.Descr.Ranking


  let to_yojson target =
    match target with
    | YanArtefact {description=t} ->
      let schema_fields =
        begin match ArtefactDescriptionYans.to_yojson t with
          | `Assoc fields -> fields
          | _ -> failwith "Expected schema to serialize to an object"
        end
      in
      `Assoc schema_fields
    | RankingArtefact {description=t} ->
      let schema_fields =
        begin match ArtefactDescriptionRanking.to_yojson t with
          | `Assoc fields -> fields
          | _ -> failwith "Expected schema to serialize to an object"
        end
      in
      `Assoc schema_fields

  let of_yojson json =
    match json with
    | `Assoc fields -> (
        match List.assoc_opt "artefact" fields with
        | Some (`String "yan") -> ArtefactDescriptionYans.of_yojson json |> Result.map (fun s -> YanArtefact {description=s})
        | Some (`String "ranking") -> ArtefactDescriptionRanking.of_yojson json |> Result.map (fun s -> RankingArtefact {description=s})
        | Some (`String unknown) -> Error ("Unrecognised artefact: " ^ unknown)
        | Some _  -> Error ("Unrecognised artefact")
        | None -> Error "Missing key: artefact"
      )
    | _ -> Error "Expected JSON object for ArtefactDescription"
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
      (* ~examples:[`Int 42] *)
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
      ~required:["phases"]
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
      ~required:["competition"; "round"; "judge_artefact_descr"; "head_judge_artefact_descr";
                 "ranking_algorithm"]

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
          ~typ:string
        (* ~examples:[
           `String "Bury";
           ] *);
        "first_name", obj @@ S.make_schema ()
          ~typ:string
        (* ~examples:[
           `String "Guillaume";
           ] *);
        "email", obj @@ S.make_schema ()
          ~typ:string
        (* ~examples:[
           `String "email@email.email";
           ] *);
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
    | Ftw.Target.Any Single {target;role} -> TargetSingle {target={target;role;target_type="single"}}
    | Ftw.Target.Any Couple {leader;follower} -> TargetCouple {target={leader;follower;target_type="couple"}}
    | Ftw.Target.Any Trouple _ -> failwith "not implemented"

  let to_ftw s =
    match s with
    | TargetSingle {target={target;role; _}} -> Ftw.Target.Any (Single {target;role})
    | TargetCouple {target={leader;follower; _}} -> Ftw.Target.Any (Couple {leader;follower})


  let to_yojson target =
    match target with
    | TargetSingle {target=t} ->
      let schema_fields =
        begin match SingleTarget.to_yojson t with
          | `Assoc fields -> fields
          | _ -> failwith "Expected schema to serialize to an object"
        end
      in
      `Assoc (schema_fields)
    | TargetCouple {target=t} ->
      let schema_fields =
        begin match CoupleTarget.to_yojson t with
          | `Assoc fields -> fields
          | _ -> failwith "Expected schema to serialize to an object"
        end
      in
      `Assoc (schema_fields)

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

(* Bib list *)
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


(* Heats *)
(* ************************************************************************* *)

(* Heat Id list *)


module SinglesHeat = struct
  type t = {
    followers : SingleTarget.t list;
    leaders : SingleTarget.t list;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"SinglesHeat"
      ~typ:object_
      ~properties:[
        "followers", obj @@ S.make_schema ()
          ~typ:array
          ~items:(ref SingleTarget.ref);
        "leaders", obj @@ S.make_schema ()
          ~typ:array
          ~items:(ref SingleTarget.ref);
      ]
      ~required:["followers"; "leaders"]

  let of_ftw (single_heat:Ftw.Heat.singles_heat) =
    let to_target role (s:Ftw.Heat.single) = begin match s with
      | {dancer; _} -> SingleTarget.{target_type="single";target=dancer;role=role}
    end in
    begin match single_heat with
      | {leaders; followers; _} -> {
          leaders=List.map (to_target Role.Leader) leaders;
          followers=List.map (to_target Role.Follower) followers;
        }
    end
end

module SinglesHeatsArray = struct
  type t = {
    heat_type : string;
    heats : SinglesHeat.t array;
  } [@@deriving yojson]


  let ref, schema =
    make_schema ()
      ~name:"SinglesHeatsArray"
      ~typ:object_
      ~properties:[
        "heat_type", obj @@ S.make_schema ()
          ~typ:string
          ~enum:[`String "single"];
        "heats", obj @@ S.make_schema ()
          ~typ:array
          ~items:(ref SinglesHeat.ref);
      ]
      ~required:["heats"]

  let of_ftw (c:Ftw.Heat.singles_heats) = match c with
    | {singles_heats;_} -> {heat_type="single";heats=Array.map SinglesHeat.of_ftw singles_heats}
end


module CouplesHeat = struct
  type t = {
    couples : CoupleTarget.t list;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"CouplesHeat"
      ~typ:object_
      ~properties:[
        "couples", obj @@ S.make_schema ()
          ~typ:array
          ~items:(ref CoupleTarget.ref);
      ]
      ~required:["couples"]

  let of_ftw (couple_heat:Ftw.Heat.couples_heat) =
    let to_target (s:Ftw.Heat.couple) = begin match s with
      | {leader;follower; _} -> CoupleTarget.{target_type="couple";leader;follower}
    end in
    begin match couple_heat with
      | {couples; _} -> {
          couples=List.map to_target couples;
        }
    end
end

module CouplesHeatsArray = struct
  type t = {
    heat_type : string;
    heats : CouplesHeat.t array;
  } [@@deriving yojson]


  let ref, schema =
    make_schema ()
      ~name:"CouplesHeatsArray"
      ~typ:object_
      ~properties:[
        "heat_type", obj @@ S.make_schema ()
          ~typ:string
          ~enum:[`String "couple"];
        "heats", obj @@ S.make_schema ()
          ~typ:array
          ~items:(ref CouplesHeat.ref);
      ]
      ~required:["heats"]

  let of_ftw (c:Ftw.Heat.couples_heats) = match c with
    | {couples_heats;_} -> {heat_type="couple";heats=Array.map CouplesHeat.of_ftw couples_heats}
end

(* Heats list *)
module HeatsArray = struct
  type t =
    | HeatsSingle of {heats: SinglesHeatsArray.t}
    | HeatsCouple of {heats: CouplesHeatsArray.t}
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"HeatsArray"
      ~typ:object_
      ~one_of:[
        (ref SinglesHeatsArray.ref);
        (ref CouplesHeatsArray.ref);
      ]
  (* todo implement interfaces *)

  let of_ftw h =
    match (h : Ftw.Heat.t) with
    | Singles sh -> HeatsSingle {heats=SinglesHeatsArray.of_ftw sh}
    | Couples ch -> HeatsCouple {heats=CouplesHeatsArray.of_ftw ch}

  let to_yojson target =
    match target with
    | HeatsSingle {heats=t} ->
      let schema_fields =
        begin match SinglesHeatsArray.to_yojson t with
          | `Assoc fields -> fields
          | _ -> failwith "Expected schema to serialize to an object"
        end
      in
      `Assoc ([("heat_type", `String "single");] @ schema_fields)
    | HeatsCouple {heats=t} ->
      let schema_fields =
        begin match CouplesHeatsArray.to_yojson t with
          | `Assoc fields -> fields
          | _ -> failwith "Expected schema to serialize to an object"
        end
      in
      `Assoc ([("heat_type", `String "couple");] @ schema_fields)

  let of_yojson json =
    match json with
    | `Assoc fields -> (
        match List.assoc_opt "heat_type" fields with
        | Some (`String "single") -> SinglesHeatsArray.of_yojson json |> Result.map (fun s -> HeatsSingle {heats=s})
        | Some (`String "couple") -> CouplesHeatsArray.of_yojson json |> Result.map (fun s -> HeatsCouple {heats=s})
        | Some (`String unknown) -> Error ("Unrecognised heat_type: " ^ unknown)
        | Some _  -> Error ("Unrecognised heat_type")
        | None -> Error "Missing key: heat_type"
      )
    | _ -> Error "Expected JSON object for HeatsArray"
end


(* Heat Ids *)
module HeatId = struct
  type t = Ftw.Heat.target_id [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"HeatId"
      ~typ:int
      (* ~examples:[`Int 42] *)
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
      ~required:["heats"]
end

(* Artefact *)
(* ************************************************************************* *)

module Yan = struct

  type t = Ftw.Artefact.yan =
    | Yes
    | Alt
    | No
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"Yan"
      ~description: {| Yan value |}
      ~typ:array
      ~items:(
        obj @@ S.make_schema ()
          ~typ:string
          ~enum:[
            `String "Yes";
            `String "Alt";
            `String "No";
          ]
      )

end


module ArtefactYans = struct

  type t = {
    artefact_type: string;
    artefact_data: Yan.t option list;
  }
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"ArtefactYans"
      ~description: {| Yes/Alt/No judging artefact |}
      ~typ:(Obj Object)
      ~properties:[
        "artefact_type", obj @@ S.make_schema ()
          ~typ:string
          ~enum:[`String "yan";];
        "artefact_data", obj @@ S.make_schema ()
          ~typ:array
          ~items:(
            obj @@ S.make_schema ()
              ~one_of:[
                obj @@ S.make_schema ()
                  ~typ:(obj S.Null);
                ref Yan.ref
              ]
          );
      ]
      ~required:["artefact_type"; "artefact_data";]

  let to_ftw a =
    let x = List.fold_left (fun acc v -> Option.bind v (fun y -> Option.map (fun l -> l @ [y]) acc)) (Some []) a.artefact_data in
    Option.map (fun l -> Ftw.Artefact.Yans l) x
end


module ArtefactRank = struct

  type t = {
    artefact_type: string;
    artefact_data: int;
  }
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"ArtefactRank"
      ~description: {| Rank of a dancer or couple |}
      ~typ:(Obj Object)
      ~properties:[
        "artefact_type", obj @@ S.make_schema ()
          ~typ:string
          ~enum:[`String "ranking"];
        "artefact_data", obj @@ S.make_schema ()
          ~typ:int;

      ]
      ~required:["artefact_type"; "artefact_data"]

end

module Artefact = struct
  type t =
    | YanArtefact of {artefact: ArtefactYans.t}
    | RankArtefact of {artefact: ArtefactRank.t}
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"Artefact"
      ~typ:object_
      ~one_of:[
        (ref ArtefactYans.ref);
        (ref ArtefactRank.ref);
      ]
      ~required:["artefact_type"; "artefact_data"; ]

  let of_ftw s =
    match s with
    | Ftw.Artefact.Yans c -> YanArtefact {artefact={artefact_type="yan";artefact_data=List.map (fun x -> Some x) c;}}
    | Ftw.Artefact.Rank r -> RankArtefact {artefact={artefact_type="ranking";artefact_data=Ftw.Rank.rank r;}}

  let to_ftw s =
    match s with
    | YanArtefact {artefact} -> ArtefactYans.to_ftw artefact
    | RankArtefact {artefact={artefact_data; _}} -> Some (Ftw.Artefact.Rank (Ftw.Rank.mk artefact_data))

  let to_yojson target =
    match target with
    | YanArtefact {artefact=t} ->
      let schema_fields =
        begin match ArtefactYans.to_yojson t with
          | `Assoc fields -> fields
          | _ -> failwith "Expected schema to serialize to an object"
        end
      in
      `Assoc schema_fields
    | RankArtefact {artefact=t} ->
      let schema_fields =
        begin match ArtefactRank.to_yojson t with
          | `Assoc fields -> fields
          | _ -> failwith "Expected schema to serialize to an object"
        end
      in
      `Assoc schema_fields

  let of_yojson json =
    match json with
    | `Assoc fields -> (
        match List.assoc_opt "artefact_type" fields with
        | Some (`String "yan") -> ArtefactYans.of_yojson json |> Result.map (fun s -> YanArtefact {artefact=s})
        | Some (`String "ranking") -> ArtefactRank.of_yojson json |> Result.map (fun s -> RankArtefact {artefact=s})
        | Some (`String unknown) -> Error ("Unrecognised artefact_type: " ^ unknown)
        | Some _  -> Error ("Unrecognised artefact_type")
        | None -> Error "Missing key: artefact_type"
      )
    | _ -> Error "Expected JSON object for Artefact"
end


(* Heat/Target/Judge/Artefact *)
(**************************************************************************)

module HeatTargetJudge = struct

  type t = {
    phase_id : PhaseId.t;
    heat_number : int;
    target : Target.t;
    judge : DancerId.t;
    description: ArtefactDescription.t;
  } [@@deriving yojson]


  let ref, schema =
    make_schema ()
      ~name:"HeatTargetJudge"
      ~typ:(Obj Object)
      ~properties:[
        "phase_id", ref PhaseId.ref;
        "heat_number", obj @@ S.make_schema()
          ~typ:int;
        "target", ref Target.ref;
        "judge", ref DancerId.ref;
        "description", (ref ArtefactDescription.ref);
      ]
      ~required:["phase_id"; "heat_number"; "target"; "judge"; "description"]

end

module HeatTargetJudgeArtefact = struct

  type t = {
    heat_target_judge : HeatTargetJudge.t;
    artefact : Artefact.t option;
  } [@@deriving yojson]


  let ref, schema =
    make_schema ()
      ~name:"HeatTargetJudgeArtefact"
      ~typ:(Obj Object)
      ~properties:[
        "heat_target_judge", (ref HeatTargetJudge.ref);
        "artefact", (ref Artefact.ref);
      ]
      ~required:["heat_target_judge";]

end

module HeatTargetJudgeArtefactArray = struct

  type t = {
    artefacts: HeatTargetJudgeArtefact.t list
  } [@@deriving yojson]


  let ref, schema =
    make_schema ()
      ~name:"HeatTargetJudgeArtefactArray"
      ~typ:object_
      ~properties:[
        "artefacts", obj @@ S.make_schema ()
          ~typ:array
          ~items:(ref HeatTargetJudgeArtefact.ref);
      ]
      ~required:["artefacts";]

end

(* Panel *)
(* ************************************************************************* *)


module SinglePanel = struct
  type t = {
    panel_type: string;
    leaders: DancerIdList.t;
    followers : DancerIdList.t;
    head : DancerId.t option;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"SinglePanel"
      ~typ:object_
      ~properties:[
        "panel_type", obj @@ S.make_schema()
          ~typ:string
          ~enum:[`String "single"];
        "leaders", ref DancerIdList.ref;
        "followers", ref DancerIdList.ref;
        "head", ref DancerId.ref;
      ]
      ~required:["panel_type"; "leaders"; "followers"]
end


module CouplePanel = struct
  type t = {
    panel_type: string;
    couples : DancerIdList.t;
    head : DancerId.t option;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"CouplePanel"
      ~typ:object_
      ~properties:[
        "panel_type", obj @@ S.make_schema()
          ~typ:string
          ~enum:[`String "couple"];
        "couples", ref DancerIdList.ref;
        "head", ref DancerId.ref;
      ]
      ~required:["panel_type"; "couples"]
end

module Panel = struct
  type t =
    | PanelSingle of {target: SinglePanel.t}
    | PanelCouple of {target: CouplePanel.t}
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"Panel"
      ~typ:object_
      ~one_of:[
        (ref SinglePanel.ref);
        (ref CouplePanel.ref);
      ]

  let of_ftw s =
    match s with
    | Ftw.Judge.Singles {leaders;followers;head} -> PanelSingle {target={leaders={dancers=leaders};followers={dancers=followers};head=head;panel_type="single"}}
    | Ftw.Judge.Couples {couples;head} -> PanelCouple {target={couples={dancers=couples};head=head;panel_type="couple"}}

  let to_ftw s =
    match s with
    | PanelSingle {target={leaders;followers;head;_}} -> Ftw.Judge.Singles {followers=followers.dancers;leaders=leaders.dancers;head=head}
    | PanelCouple {target={couples;head; _}} -> Ftw.Judge.Couples {couples=couples.dancers;head=head}


  let to_yojson target =
    match target with
    | PanelSingle {target=t} ->
      let schema_fields =
        begin match SinglePanel.to_yojson t with
          | `Assoc fields -> fields
          | _ -> failwith "Expected schema to serialize to an object"
        end
      in
      `Assoc ([("panel_type", `String "single");] @ schema_fields)
    | PanelCouple {target=t} ->
      let schema_fields =
        begin match CouplePanel.to_yojson t with
          | `Assoc fields -> fields
          | _ -> failwith "Expected schema to serialize to an object"
        end
      in
      `Assoc ([("panel_type", `String "couple");] @ schema_fields)

  let of_yojson json =
    match json with
    | `Assoc fields -> (
        match List.assoc_opt "panel_type" fields with
        | Some (`String "single") -> SinglePanel.of_yojson json |> Result.map (fun s -> PanelSingle {target=s})
        | Some (`String "couple") -> CouplePanel.of_yojson json |> Result.map (fun s -> PanelCouple {target=s})
        | Some (`String unknown) -> Error ("Unrecognised panel_type: " ^ unknown)
        | Some _  -> Error ("Unrecognised panel_type")
        | None -> Error "Missing key: panel_type"
      )
    | _ -> Error "Expected JSON object for Panel"
end

(* RANKS *)
(**************************************************************************)

module TargetRPSSRank = struct

  type t = {
    ranking_type: string;
    target : Target.t;
    rank: int option;
    artefact_list: ArtefactRank.t list;
    ranking_details: string list; (* one element per rank, to plot on the right hand side*)
  } [@@deriving yojson]


  let ref, schema =
    make_schema ()
      ~name:"TargetRPSSRank"
      ~typ:(Obj Object)
      ~properties:[
        "ranking_type", obj @@ S.make_schema()
          ~typ:string
          ~enum:[`String "rpss"];
        "target", (ref Target.ref);
        "artefact_list", obj @@ S.make_schema()
          ~typ:array
          ~items:(ref ArtefactRank.ref);
        "rank",  obj @@ S.make_schema()
          ~typ:int;
        "ranking_details", obj @@ S.make_schema()
          ~typ:array
          ~items:(obj @@ S.make_schema()
                    ~typ:string);
      ]
      ~required:["ranking_type";"target";"rank";"ranking_details"]
end

module TargetYanRank = struct

  type t = {
    ranking_type: string;
    target : Target.t;
    rank: int option;
    artefact_list: ArtefactYans.t list;
    score: float option;
  } [@@deriving yojson]


  let ref, schema =
    make_schema ()
      ~name:"TargetYanRank"
      ~typ:(Obj Object)
      ~properties:[
        "ranking_type", obj @@ S.make_schema()
          ~typ:string
          ~enum:[`String "yan"];
        "target", (ref Target.ref);
        "artefact_list", obj @@ S.make_schema()
          ~typ:array
          ~items:(ref ArtefactYans.ref);
        "rank",  obj @@ S.make_schema()
          ~typ:int;
        "score", obj @@ S.make_schema()
          ~typ:int;
      ]
      ~required:["ranking_type"; "target"; "artefact_list";"rank";"score"]
end

module TargetRank = struct

  type t =
    | YanRank of {rank: TargetYanRank.t}
    | RPSSRank of {rank: TargetRPSSRank.t}
  [@@deriving yojson]


  let ref, schema =
    make_schema ()
      ~name:"TargetRank"
      ~typ:object_
      ~one_of:[
        (ref TargetYanRank.ref);
        (ref TargetRPSSRank.ref);
      ]

  (* TODO implement to_yojson  *)
end




module PhaseRanking = struct

  type t = {
    (* hypothesis dense rank
       the first inner "TargetRank.t list" is the list of targets that are ranked first.
       It should not be empty.
       the second inner "TargetRank.t list" is the list of targets that ranked second.
       the rank index should match the TargetRank.rank value.
       it is expected that most ranks contains a list of size 1
       the last inner "TargetRank.t list" is the list of targets that are unranked / ranked last.
       the frontend doesn't know the condition for the ranking to be valid.
       It just applies warning colors to ranks that contains more than 1 target.
    *)
    ranks: TargetRank.t list list;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"PhaseRanks"
      ~typ:object_
      ~properties:[
        "ranks", obj @@ S.make_schema()
          ~typ:array
          ~items:(
            obj @@ S.make_schema()
              ~typ:array
              ~items:(ref TargetRank.ref)
          );
      ]
      ~required:["ranks"]
end




module NextPhaseFormData = struct

  type t = {
    number_of_targets_to_promote: int;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"NextPhaseFormData"
      ~typ:object_
      ~properties:[
        "number_of_targets_to_promote", obj @@ S.make_schema()
          ~typ:int;
      ]
      ~required:["number_of_targets_to_promote"]
end


module InitHeatsFormData = struct

  type t = {
    min_number_of_targets: int;
    max_number_of_targets: int;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"InitHeatsFormData"
      ~typ:object_
      ~properties:[
        "min_number_of_targets", obj @@ S.make_schema()
          ~typ:int;
        "max_number_of_targets", obj @@ S.make_schema()
          ~typ:int;
      ]
      ~required:["min_number_of_targets"; "max_number_of_targets"]
end

module RankingResults = struct
  type t =
    | Not_present       (* or unknown *)
    | Present           (* but rank unknown *)
    | Ranked of int (* actual rank *)
  [@@deriving yojson]


  let ref, schema =
    make_schema ()
      ~name:"RankingResults"
      ~typ:object_
      ~one_of:[
        obj @@ S.make_schema()
          ~typ:object_
          ~properties:[
            "result_type", obj @@ S.make_schema()
              ~typ:string
              ~enum:[`String "ranked"];
            "ranked", obj @@ S.make_schema()
              ~typ:int;
          ];
        obj @@ S.make_schema()
          ~typ:object_
          ~properties:[
            "result_type", obj @@ S.make_schema()
              ~typ:string
              ~enum:[`String "present"];
            "present", obj @@ S.make_schema()
              ~typ:boolean
              ~enum:[`Bool true]
          ];
        obj @@ S.make_schema()
          ~typ:object_
          ~properties:[
            "result_type", obj @@ S.make_schema()
              ~typ:string
              ~enum:[`String "not_present"];
            "present", obj @@ S.make_schema()
              ~typ:boolean
              ~enum:[`Bool false]
          ];
      ]

  let to_yojson a =
    match a with
    | Not_present -> `Assoc [("present", `Bool false); ("result_type", `String "not_present")]
    | Present -> `Assoc [("present", `Bool true); ("result_type", `String "present")]
    | Ranked i -> `Assoc [("ranked", `Int i); ("result_type", `String "ranked")]

  let of_ftw (r:Ftw.Results.aux) =
    match r with
    | Not_present -> Not_present
    | Present -> Present
    | Ranked i -> Ranked (Ftw.Rank.rank i)
end

module DancerCompetitionResults = struct

  type p = {
    prelims :       RankingResults.t;
    octofinals :    RankingResults.t;
    quarterfinals : RankingResults.t;
    semifinals :    RankingResults.t;
    finals :        RankingResults.t;
  } [@@deriving yojson]

  type t = {
    competition : CompetitionId.t;
    dancer : DancerId.t;
    role : Role.t;
    result : p;
    points : int;
  } [@@deriving yojson]


  let ref, schema =
    make_schema ()
      ~name:"DancerCompetitionResults"
      ~typ:object_
      ~properties:[
        "competition", ref CompetitionId.ref;
        "dancer", ref DancerId.ref;
        "role", ref Role.ref;
        "result", obj @@ S.make_schema()
          ~typ:object_
          ~properties:[
            "prelims", ref RankingResults.ref;
            "octofinals", ref RankingResults.ref;
            "quarterfinals", ref RankingResults.ref;
            "semifinals", ref RankingResults.ref;
            "finals", ref RankingResults.ref;
          ]
          ~required:["prelims"; "octofinals"; "quarterfinals"; "semifinals"; "finals"];
        "points", obj @@ S.make_schema()
          ~typ:int;
      ]
      ~required:["competition"; "dancer"; "role"; "result"; "points"]

  let of_ftw (r:Ftw.Results.r) =
    let result = {
      prelims=RankingResults.of_ftw r.result.prelims;
      octofinals=RankingResults.of_ftw r.result.octofinals;
      quarterfinals=RankingResults.of_ftw r.result.quarterfinals;
      semifinals=RankingResults.of_ftw r.result.semifinals;
      finals=RankingResults.of_ftw r.result.finals;
    } in
    {competition=r.competition;dancer=r.dancer;role=r.role;result=result;points=r.points}
end

module DancerCompetitionResultsList = struct
  type t = {
    results : DancerCompetitionResults.t list;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"DancerCompetitionResultsList"
      ~typ:object_
      ~properties:[
        "results", obj @@ S.make_schema ()
          ~typ:array
          ~items:(ref DancerCompetitionResults.ref);
      ]
      ~required:["results"]
end
