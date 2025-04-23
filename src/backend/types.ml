
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
      ~typ:string
      ~enum:[
        `String "Prelims";
        `String "Octofinals";
        `String "Quarterfinals";
        `String "Semifinals";
        `String "Finals";

      ]
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
          ~examples:[`String "P4T"];
        "kind", ref Kind.ref;
        "category", ref Category.ref;
        "n_leaders", obj @@ S.make_schema () ~typ:int;
        "n_follows", obj @@ S.make_schema () ~typ:int;
      ]
end

(* Artefact *)
(* ************************************************************************* *)

module YanCriterionWeight = struct
  type t = Ftw.Ranking.Algorithm.yan_weight [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"YanCriterionWeight"
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
    weights: YanCriterionWeight.t list;
    head_weights: YanCriterionWeight.t list;
  }
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"RankingYanWeighted"
      ~typ:array
      ~description: {| Ranking algorithm for Yan_weighted |}
      ~items:(ref YanCriterionWeight.ref)

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
        weights : YanCriterionWeight.t list;
        head_weights : YanCriterionWeight.t list;
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
              ~items:(ref YanCriterionWeight.ref);
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
          let weights = sequence (List.map YanCriterionWeight.of_yojson weights) in
          let head_weights = sequence (List.map YanCriterionWeight.of_yojson head_weights) in

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
            ("weights", `List (List.map YanCriterionWeight.to_yojson weights));
            ("head_weights", `List (List.map YanCriterionWeight.to_yojson head_weights));
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
end
