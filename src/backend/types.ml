
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

module YanArtefactDescription = struct
  type t = (string * YanCriterionWeight.t) list [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"YanArtefactDescription"
      ~typ:(Obj Object)
      ~description: {| artefact of type yan.
For a yan artefact, yan_criterion property should be set. |}
      ~additional_properties:(ref YanCriterionWeight.ref)

  let of_yojson = function
    | `Assoc entries ->
      (* We will convert the key-value pairs in the JSON object into a list of pairs (key, value) *)
      let open Result in
      let list_parsed = List.fold_left (fun acc (k, v) ->
          let parsed_row = map (fun parsed -> (k, parsed)) (YanCriterionWeight.of_yojson v)
          in
          fold ~ok:(fun r_list -> map (fun row -> row::r_list) parsed_row)
            ~error:(fun err -> Error err) acc
        ) (Ok []) entries
      in
      list_parsed
    | _ -> Error "YanArtefactDescription.t: expected JSON object"

  let to_yojson artefact =
    let criterion_list = List.map (fun (k, v) -> (k, YanCriterionWeight.to_yojson v)) artefact
    in
    `Assoc criterion_list

  let of_ftw criterion_names criterion_weights =
    match criterion_names, criterion_weights with
    | Ftw.Artefact.Descr.Yans { criterion }, Ftw.Ranking.Algorithm.Yan_weighted { weights; head_weights} ->
      List.map2 (fun key item -> (key, item)) criterion weights
    | _ -> assert false

  let to_ftw yan_criterion =
    let pairs = yan_criterion in
    (
      Ftw.Artefact.Descr.Yans {criterion=List.map (fun (c, _) -> c) pairs},
      Ftw.Ranking.Algorithm.Yan_weighted {weights=List.map (fun (_, w) -> w) pairs}
    )
end

module RankingArtefactDescription = struct
  type t = string [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"RankingArtefactDescription"
      ~typ:string
      ~description: {| artefact of type yan.
For a yan artefact, yan_criterion property should be set. |}

  let of_ftw (algorithm_for_ranking: Ftw.Ranking.Algorithm.t) =
    match algorithm_for_ranking with
    | RPSS -> "RPSS"
    | _ -> assert false

  let to_ftw algorithm_for_ranking =
    match algorithm_for_ranking with
    | "RPSS" ->
      (Ftw.Artefact.Descr.Ranking, Ftw.Ranking.Algorithm.RPSS)
    | _ -> assert false

end


module ArtefactDescription = struct

  type t =
    | Yan of {yan_criterion: YanArtefactDescription.t}
    | Ranking of {algorithm_for_ranking: RankingArtefactDescription.t}
  [@@deriving yojson]

  let ref, schema =
    make_schema ()
      ~name:"ArtefactDescription"
      ~description: {| artefact is either ranking or yan.
        For a ranking artefact, ranking_algorithm property should be specified.
        For a yan artefact, yan_criterion property should be set. |}
      ~one_of:[
        obj @@ S.make_schema()
          ~typ:(Obj Object)
          ~properties:[
            "yan", (ref YanArtefactDescription.ref);
          ];
        obj @@ S.make_schema()
          ~typ:(Obj Object)
          ~properties:[
            "ranking", (ref RankingArtefactDescription.ref);
          ];
      ]



  let of_yojson = function
    | `Assoc props -> (
        match List.assoc_opt "yan" props, List.assoc_opt "ranking" props with
        | Some descr, None ->
          YanArtefactDescription.of_yojson descr
          |> Result.map (fun yan_descr -> Yan { yan_criterion = yan_descr })

        | None, Some descr ->
          RankingArtefactDescription.of_yojson descr
          |> Result.map (fun algo -> Ranking { algorithm_for_ranking = algo })

        | Some _, Some _ ->
          Error "ArtefactDescription.of_yojson: cannot have both 'yan' and 'ranking'"

        | None, None ->
          Error "ArtefactDescription.of_yojson: missing 'yan' or 'ranking'"
      )
    | _ -> Error "ArtefactDescription.of_yojson: expected JSON object"


  let to_yojson artefact =
    match artefact with
    | Yan {yan_criterion} -> (`Assoc [("yan", (YanArtefactDescription.to_yojson yan_criterion))])
    | Ranking {algorithm_for_ranking} -> (`Assoc [("ranking", RankingArtefactDescription.to_yojson algorithm_for_ranking)])

  let of_ftw artefact_description ranking_algorithm =
    match artefact_description, ranking_algorithm with
    | Ftw.Artefact.Descr.Yans { criterion=_; }, Ftw.Ranking.Algorithm.Yan_weighted { weights=_;} ->
      let yan_criterion = YanArtefactDescription.of_ftw artefact_description ranking_algorithm
      in
      Yan { yan_criterion=yan_criterion; }
    | Ftw.Artefact.Descr.Ranking, Ftw.Ranking.Algorithm.RPSS ->
      Ranking {algorithm_for_ranking=RankingArtefactDescription.of_ftw ranking_algorithm}
    | _, _ -> assert false

  let to_ftw artefact_description =
    match artefact_description with
    | Yan { yan_criterion; } -> YanArtefactDescription.to_ftw yan_criterion
    | Ranking {algorithm_for_ranking;} -> RankingArtefactDescription.to_ftw algorithm_for_ranking
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
        "judge_artefact_description", ref ArtefactDescription.ref;
        "head_judge_artefact_description", ref ArtefactDescription.ref
      ]

  let artefact_to_ftw p =
    let judge_artefact_description = p.judge_artefact_description
    in
    let head_judge_artefact_description = p.head_judge_artefact_description
    in
    let full_artefact_description = match judge_artefact_description, head_judge_artefact_description with
      | Yan {yan_criterion=judge_criterion}, Yan {yan_criterion=head_criterion} ->
        let criterion = List.concat [
            (List.map (fun (k,v) -> (k, v)) judge_criterion);
            (List.map (fun (k,v) -> (k, v)) head_criterion);
          ]
        in
        ArtefactDescription.Yan {yan_criterion=criterion}
      | Ranking {algorithm_for_ranking=jr}, Ranking {algorithm_for_ranking=hr} when jr = hr ->
        Ranking {algorithm_for_ranking=jr}
      | Ranking {algorithm_for_ranking=_;}, Ranking {algorithm_for_ranking=_;} ->
        assert false
      | _, _ -> assert false
    in
    let (_, ranking_algorithm) = ArtefactDescription.to_ftw full_artefact_description in
    let (judge_artefact_descr, _) = ArtefactDescription.to_ftw judge_artefact_description in
    let (head_judge_artefact_descr, _ ) = ArtefactDescription.to_ftw head_judge_artefact_description in
    (
      ranking_algorithm,
      judge_artefact_descr,
      head_judge_artefact_descr
    )

  let artefact_of_ftw ranking_algorithm judge_artefact_descr head_judge_artefact_descr =
    match judge_artefact_descr, head_judge_artefact_descr with
    | Ftw.Artefact.Descr.Ranking, Ftw.Artefact.Descr.Ranking ->
      (
        ArtefactDescription.of_ftw judge_artefact_descr ranking_algorithm,
        ArtefactDescription.of_ftw judge_artefact_descr ranking_algorithm
      )
    | Ftw.Artefact.Descr.Yans {criterion=ja;}, Ftw.Artefact.Descr.Yans {criterion=ha;} ->
      let full_descr = Ftw.Artefact.Descr.Yans {criterion=List.concat [ja;ha];}
      in
      let full_artefact = ArtefactDescription.of_ftw full_descr ranking_algorithm
      in
      let artefact_list = (match full_artefact with
          | Yan {yan_criterion} -> yan_criterion
          | _ -> assert false
        )
      in
      let judge_artefact = Seq.take (List.length ja) (List.to_seq artefact_list)
      in
      let head_artefact = Seq.take (List.length ha) (List.to_seq @@ List.rev artefact_list)
      in
      (
        Yan {yan_criterion=List.of_seq judge_artefact},
        Yan {yan_criterion=List.of_seq head_artefact}
      )
    | _, _ -> assert false

  let of_ftw phase =
    let (judge_artefact, head_artefact) = artefact_of_ftw
        (Ftw.Phase.ranking_algorithm phase)
        (Ftw.Phase.judge_artefact_descr phase)
        (Ftw.Phase.head_judge_artefact_descr phase)
    in
    {
      competition=Ftw.Phase.competition phase;
      round=Ftw.Phase.round phase;
      judge_artefact_description=judge_artefact;
      head_judge_artefact_description=head_artefact;
    }

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
