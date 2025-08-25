
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
    | Ftw.Ranking.Algorithm.RPSS -> Ranking {algorithm={algorithm="ranking";algorithm_name="RPSS"}}

  let to_ftw s =
    match s with
    | Yan_weighted {algorithm={weights;head_weights; _}} -> Ftw.Ranking.Algorithm.Yan_weighted {weights;head_weights}
    | Ranking {algorithm={algorithm_name="RPSS";_}} -> Ftw.Ranking.Algorithm.RPSS
    | Ranking {algorithm=_} -> Ftw.Ranking.Algorithm.RPSS


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
    | YanArtefact of {artefact: ArtefactDescriptionYans.t}
    | RankingArtefact of {artefact: ArtefactDescriptionRanking.t}
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
    | Ftw.Artefact.Descr.Yans {criterion;} -> YanArtefact {artefact={artefact="yan";artefact_data=criterion}}
    | Ftw.Artefact.Descr.Ranking -> RankingArtefact {artefact={artefact="ranking";artefact_data=()}}

  let to_ftw s =
    match s with
    | YanArtefact {artefact={artefact_data; _}} -> Ftw.Artefact.Descr.Yans {criterion=artefact_data;}
    | RankingArtefact {artefact=_} -> Ftw.Artefact.Descr.Ranking


  let to_yojson target =
    match target with
    | YanArtefact {artefact=t} ->
      let schema_fields =
        begin match ArtefactDescriptionYans.to_yojson t with
          | `Assoc fields -> fields
          | _ -> failwith "Expected schema to serialize to an object"
        end
      in
      `Assoc schema_fields
    | RankingArtefact {artefact=t} ->
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
        | Some (`String "yan") -> ArtefactDescriptionYans.of_yojson json |> Result.map (fun s -> YanArtefact {artefact=s})
        | Some (`String "ranking") -> ArtefactDescriptionRanking.of_yojson json |> Result.map (fun s -> RankingArtefact {artefact=s})
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
          ~examples:[
            `String "Bury";
          ];
        "first_name", obj @@ S.make_schema ()
          ~typ:string
          ~examples:[
            `String "Guillaume";
          ];
        "email", obj @@ S.make_schema ()
          ~typ:string
          ~examples:[
            `String "email@email.email";
          ];
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
    target_type : string;
    heats : SinglesHeat.t array;
  } [@@deriving yojson]


  let ref, schema =
    make_schema ()
      ~name:"SinglesHeatsArray"
      ~typ:object_
      ~properties:[
        "heats", obj @@ S.make_schema ()
          ~typ:array
          ~items:(ref SinglesHeat.ref);
      ]
      ~required:["heats"]

  let of_ftw (c:Ftw.Heat.singles_heats) = match c with
    | {singles_heats;_} -> {target_type="single";heats=Array.map SinglesHeat.of_ftw singles_heats}
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
    target_type : string;
    heats : CouplesHeat.t array;
  } [@@deriving yojson]


  let ref, schema =
    make_schema ()
      ~name:"CouplesHeatsArray"
      ~typ:object_
      ~properties:[
        "heats", obj @@ S.make_schema ()
          ~typ:array
          ~items:(ref CouplesHeat.ref);
      ]
      ~required:["heats"]

  let of_ftw (c:Ftw.Heat.couples_heats) = match c with
    | {couples_heats;_} -> {target_type="single";heats=Array.map CouplesHeat.of_ftw couples_heats}
end

(* Heats list *)
module HeatsArray = struct
  type t =
    | HeatsSingle of {heats: SinglesHeatsArray.t}
    | HeatsCouple of {target: SinglesHeatsArray.t}
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
end


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
      ~required:["heats"]
end
