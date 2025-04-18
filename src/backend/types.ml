
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

module S = Openapi_router.Json_Schema

(* Helper functions *)
(* ************************************************************************* *)

let obj o = S.Obj o
let ref name = S.Ref name

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
          ~examples:[`String "Event not found"]
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
      ~properties:[
        "day", obj @@ S.make_schema ()
          ~typ:int
          ~examples:[`Int 1; `Int 31];
        "month", obj @@ S.make_schema ()
          ~typ:int
          ~examples:[`Int 1; `Int 12];
        "year", obj @@ S.make_schema ()
          ~typ:int
          ~examples:[`Int 2019; `Int 2024];
      ]
end

(* Competition Kinds *)
module Kind = struct
  type t = Ftw.Kind.t =
    | Routine
    | Strictly
    | JJ_Strictly
    | Jack_and_Jill
  [@@deriving yojson, enum, show]

  let all = List.filter_map of_enum (List.init (to_enum Jack_and_Jill + 1) Fun.id)

  let ref, schema =
    make_schema ()
      ~name:"Kind"
      ~typ:array
      ~items:(
        obj @@ S.make_schema ()
          ~typ:string
          ~enum:(List.map
                   (fun kind -> `String (show kind))
                   all
                )
      )
end

(* Competition Division *)
module Division = struct
  type t = Ftw.Division.t =
    | Novice
    | Intermediate
    | Advanced
  [@@deriving yojson, enum, show]

  let all = List.filter_map of_enum (List.init (to_enum Advanced + 1) Fun.id)

  let ref, schema =
    make_schema ()
      ~name:"Division"
      ~typ:array
      ~items:(
        obj @@ S.make_schema ()
          ~typ:string
          ~enum:(List.map
                   (fun division -> `String (show division))
                   all
                )
      )
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
  [@@deriving yojson, enum, show]

  let all = List.filter_map of_enum (List.init (to_enum Invited + 1) Fun.id)

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
          ~enum:(List.map
                   (fun cat -> `String (show cat))
                   all
                )
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
  [@@deriving yojson, enum, show]

  let all = List.filter_map of_enum (List.init (to_enum Finals + 1) Fun.id)

  let ref, schema =
    make_schema ()
      ~name:"Round"
      ~typ:array
      ~items:(
        obj @@ S.make_schema ()
          ~typ:string
          ~enum:(List.map
                   (fun round -> `String (show round))
                   all
                )
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
      ~examples:[`Int 42]
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
          ~examples:[`String "P4T"];
        "start_date", ref Date.ref;
        "end_date", ref Date.ref;
      ]
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
      ~examples:[`Int 42]
end

(* Competition Id list *)
module CompetitionIdList = struct
  type t = {
    comps : CompetitionId.t list;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"CompetitionIdList"
      ~typ:object_
      ~properties:[
        "comps", obj @@ S.make_schema ()
          ~typ:array
          ~items:(ref CompetitionId.ref);
      ]
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
          ~examples:[`String "P4T"];
        "kind", ref Kind.ref;
        "category", ref Category.ref;
        "leaders_count", obj @@ S.make_schema () ~typ:int;
        "followers_count", obj @@ S.make_schema () ~typ:int;
      ]
end

(* Artefact *)
(* ************************************************************************* *)

module YanCriterion = struct
  type t = string * Ftw.Ranking.Algorithm.yan_weight [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"YanCriterion"
      ~typ:(Obj Object)
      ~additional_properties:(
        obj @@ S.make_schema ()
          ~properties:[
            "yes", obj @@ S.make_schema ()
              ~typ:int;
            "alt", obj @@ S.make_schema ()
              ~typ:int;
            "no", obj @@ S.make_schema ()
              ~typ:int;
          ]
      )
end


module ArtefactDescription = struct

  module StrMap = Map.Make (String)

  type t = {
    artefact: string;
    yan_criterion: YanCriterion.t list option;
    algorithm_for_ranking: string option;
  }[@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"ArtefactDescription"
      ~typ:(Obj Object)
      ~description: {| artefact is either ranking or yan.
        For a ranking artefact, ranking_algorithm property should be specified.
        For a yan artefact, yan_criterion property should be set. |}
      ~properties:[
        "artefact", obj @@ S.make_schema ()
          ~typ:string
          ~enum:[`String "ranking"; `String "yan"];
        "yan_criterion", obj @@ S.make_schema ()
          ~typ:(Obj Array)
          ~items:(ref YanCriterion.ref);
        "algorithm_for_ranking", obj @@ S.make_schema ()
          ~typ:string
      ]
      ~required:["artefact"]


  let of_ftw artefact_description ranking_algorithm =
    match artefact_description, ranking_algorithm with
    | Ftw.Artefact.Descr.Yans { criterion }, Ftw.Ranking.Algorithm.Yan_weighted { weights } ->
      { artefact = "yan";
        yan_criterion = Some (List.map2 (fun c w -> (c,w)) criterion weights);
        algorithm_for_ranking = None }
    | Ftw.Artefact.Descr.Ranking, Ftw.Ranking.Algorithm.RPSS ->
      { artefact = "ranking";
        yan_criterion = None;
        algorithm_for_ranking = Some "RPSS" }
    | _, _ -> assert false

  let to_ftw {artefact; yan_criterion; algorithm_for_ranking} =
    match artefact, yan_criterion, algorithm_for_ranking with
    | "ranking", None, Some _ -> (Ftw.Artefact.Descr.Ranking, Ftw.Ranking.Algorithm.RPSS)
    | "yan", Some yan_criterion_list, None -> (
        Yans {criterion=List.map (fun (c,_) -> c) yan_criterion_list},
        Yan_weighted {weights=List.map (fun (_, w) -> w) yan_criterion_list}
      )
    | _ -> assert false
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
    judge_artefact_description : ArtefactDescription.t;
    head_judge_artefact_description : ArtefactDescription.t;
  } [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"Phase"
      ~typ:(Obj Object)
      ~properties:[
        "competition", ref CompetitionId.ref;
        "round", ref Round.ref;
        "judge_artefact_description", obj @@ S.make_schema ()
          ~typ:(ref ArtefactDescription.ref);
        "head_judge_artefact_description", obj @@ S.make_schema ()
          ~typ:(ref ArtefactDescription.ref)
      ]
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
      ~examples:[`Int 42]
end

(* Dancer Id list *)
module DancerIdList = struct
  type t = {
    phases : DancerId.t list;
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
end



(* Heats *)
(* ************************************************************************* *)

(* Heat Ids *)
module HeatId = struct
  type t = Ftw.Heat.passage_id [@@deriving yojson]

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
end
