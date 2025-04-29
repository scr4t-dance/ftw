
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw.promotion"

(* Promotion rules *)
(* ************************************************************************* *)

type update =
  | None
  | Downgrade_to of Divisions.t
  | Upgrade_to_at_least of Divisions.t

type reason =
  | Participation
  | Invited
  | Qualifying_finalist
  | Inter_finalist
  | Points_soft
  | Points_hard
  | Points_auto

let reason_to_string = function
  | Participation -> "Participation"
  | Invited -> "Invited"
  | Qualifying_finalist -> "Qualifying finalist"
  | Inter_finalist -> "Inter finalist (transition period)"
  | Points_soft -> "Soft"
  | Points_hard -> "Hard"
  | Points_auto -> "Auto"


(* Promotion rules *)
(* ************************************************************************* *)

type points = Division.t -> int

type rule = Category.t -> Results.r -> points -> update

(* First participants in competition have an all-zero divs,
   and thus it need to be upgraded to at least novice. *)
let participation : rule = fun category _result _points ->
  match category with
  | Competitive _ -> Upgrade_to_at_least Divisions.Novice
  | Non_competitive _ -> None

(* Dancers that have been invited to an invitational Jack&Jill
   are upgraded to a division above that of Novice *)
let invited : rule = fun category _result _points ->
  match category with
  | Non_competitive Invited -> Upgrade_to_at_least Intermediate
  | _ -> None

(* Dancers that have reached the finals of a qualifying competition
   are also eligible for division upgrade *)
let qualifying_finalist : rule = fun category result _points ->
  match category, result.result.finals with
  | Non_competitive Qualifying, (Present | Ranked _ ) ->
    Upgrade_to_at_least Intermediate
  | _ -> None

(* exceptional rule for the beginning/transition:
   reaching finals in Inter gives right to the Inter division *)
let inter_finalist : rule = fun category result _points ->
  match category, result.result.finals with
  | Competitive Intermediate, (Present | Ranked _ ) ->
    Upgrade_to_at_least Intermediate
  | _ -> None

(* soft promotion: once a threshold of points is reached in a division,
   gives access to a higher division. *)
let soft_promote div threshold upgrade_div : rule =
  fun category result points ->
  match category with
  | Competitive d when Division.equal d div && result.points > 0 ->
    if points div >= threshold then Upgrade_to_at_least upgrade_div else None
  | _ -> None

(* hard/forced promotion: one a threshold of points is reached in a division,
   gives access to a higher division, *and* removes access to the current/lower
   div *)
let hard_promote div threshold upgrade_div : rule =
  fun category result points ->
  match category with
  | Competitive d when Division.equal d div && result.points > 0 ->
    if points div >= threshold
    then Upgrade_to_at_least upgrade_div
    else None
  | _ -> None

(* auto-promotion: earning any points in a division results in gaining
   access to that division, and losing access to lower divisions. *)
let auto_promote div upgrade_div : rule =
  fun category result _points ->
  match category with
  | Competitive d when Division.equal d div && result.points > 0 ->
    Upgrade_to_at_least upgrade_div
  | _ -> None


(* ************************************************************************* *)
(* Sets of rules and dates *)
(* ************************************************************************* *)

let rules =
  Date.Itm.of_list [
    (* Rules for the beginning/transition period:
       i.e. until the end of 2022 *)
    Date.mk ~day:1 ~month:1 ~year:2000, [
      (* transition rules *)
      Invited, invited;
      Inter_finalist, inter_finalist;
      Qualifying_finalist, qualifying_finalist;
      (* rules for novice points *)
      Points_hard, hard_promote Novice 12 Intermediate;
      Points_soft, soft_promote Novice 6 Novice_Intermediate;
      (* rules for inter points *)
      Points_hard, hard_promote Intermediate 36 Advanced;
      Points_soft, soft_promote Intermediate 24 Intermediate_Advanced;
      Points_auto, auto_promote Intermediate Intermediate;
      (* rules for adv points *)
      Points_auto, auto_promote Advanced Advanced;
      (* misc *)
      Participation, participation;
    ];

    Date.mk ~day:31 ~month:12 ~year:2022, [
      (* rules for novice points *)
      Points_hard, hard_promote Novice 12 Intermediate;
      Points_soft, soft_promote Novice 6 Novice_Intermediate;
      (* rules for inter points *)
      Points_hard, hard_promote Intermediate 36 Advanced;
      Points_soft, soft_promote Intermediate 24 Intermediate_Advanced;
      Points_auto, auto_promote Intermediate Intermediate;
      (* rules for adv points *)
      Points_auto, auto_promote Advanced Advanced;
      (* misc *)
      Participation, participation;
    ];

  ]

let update_with_new_result st (result : Results.r) =
  (* Fetch/extract some info *)
  let competition = Competition.get st result.competition in
  let event = Event.get st (Competition.event competition) in
  let id = result.dancer in
  let dancer = Dancer.get ~st id in
  let dancer_divs =
    match result.role with
    | Leader -> Dancer.as_leader dancer
    | Follower -> Dancer.as_follower dancer
  in
  (* lazy computation of cumulative points total by division *)
  let points =
    let novice =
      lazy (Results.all_points ~st ~dancer:id ~role:result.role ~div:Novice)
    in
    let inter =
      lazy (Results.all_points ~st ~dancer:id ~role:result.role ~div:Intermediate)
    in
    let adv =
      lazy (Results.all_points ~st ~dancer:id ~role:result.role ~div:Advanced)
    in
    (fun div ->
       match (div : Division.t) with
      | Novice -> Lazy.force novice
      | Intermediate -> Lazy.force inter
      | Advanced -> Lazy.force adv)
  in
  (* Compute the new division according to the rules *)
  let new_divs =
    List.fold_left (fun divs (reason, (rule : rule)) ->
        let new_div : Divisions.t option =
          match rule (Competition.category competition) result points with
          | None -> None
          | Downgrade_to new_divs ->
            if Divisions.equal divs new_divs then None else Some divs
          | Upgrade_to_at_least new_divs ->
            if Divisions.compare divs new_divs < 0
            then Some new_divs
            else None
        in
        match new_div with
        | None -> divs
        | Some new_divs ->
          Logs.debug ~src (fun k->
              k "Promotion (%s)\t%-15s-> %-15s : %a"
                (reason_to_string reason)
                (Divisions.to_string divs)
                (Divisions.to_string new_divs)
                Dancer.print_compact dancer
            );
          new_divs
      ) dancer_divs (Date.Itm.find_exn rules (Event.start_date event))
  in
  (* Record the new divisions for the dancer.
     TODO: add a DB SQL table to store promotions. *)
  if Divisions.equal dancer_divs new_divs then ()
  else begin
    Dancer.update_divisions ~st ~dancer:id ~role:result.role ~divs:new_divs
  end


