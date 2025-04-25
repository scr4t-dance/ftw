
(* This file is free software, part of FTW. See file "LICENSE" for more information *)


let src = Logs.Src.create "ftw.promotion"

(* ************************************************************************* *)
(* Promotion rules *)
(* ************************************************************************* *)

type update =
  | Upgrade_to of Divisions.t

let apply divs updates =
  List.fold_left (fun acc update ->
      match update with
      | Upgrade_to divs -> Divisions.max divs acc
    ) divs updates


(* ************************************************************************* *)
(* Promotion rules *)
(* ************************************************************************* *)

type points = Division.t -> int

type rule = Category.t -> Results.r -> points -> update list

(* Dancers that have been invited to an invitational Jack&Jill
   are upgraded to a division above that of Novice *)
let invited : rule = fun category _result _points ->
  match category with
  | Non_competitive Invited -> [ Upgrade_to Intermediate ]
  | _ -> []

(* Dancers that have reached the finals of a qualifying competition
   are also eligible for division upgrade *)
let qualifying_finalist : rule = fun category result _points ->
  match category, result.result.finals with
  | Non_competitive Qualifying, (Present | Ranked _ ) ->
    [ Upgrade_to Intermediate ]
  | _ -> []

(* exceptional rule for the beginning/transition:
   reaching finals in Inter gives right to the Inter division *)
let inter_finalist : rule = fun category result _points ->
  match category, result.result.finals with
  | Competitive Intermediate, (Present | Ranked _ ) ->
    [ Upgrade_to Intermediate ]
  | _ -> []

(* soft promotion: once a threshold of points is reached in a division,
   gives access to a higher division. *)
let soft_promote div threshold upgrade_div : rule =
  fun category result points ->
  match category with
  | Competitive d when Division.equal d div && result.points > 0 ->
    if points div >= threshold then [ Upgrade_to upgrade_div ] else []
  | _ -> []

(* hard/forced promotion: one a threshold of points is reached in a division,
   gives access to a higher division, *and* removes access to the current/lower
   div *)
let hard_promote div threshold upgrade_div : rule =
  fun category result points ->
  match category with
  | Competitive d when Division.equal d div && result.points > 0 ->
    if points div >= threshold then
      [ Upgrade_to upgrade_div ]
    else
      []
  | _ -> []

(* auto-promotion: earning any points in a division results in gaining
   access to that division, and losing access to lower divisions. *)
let auto_promote div upgrade_div : rule =
  fun category result _points ->
  match category with
  | Competitive d when Division.equal d div && result.points > 0 ->
    [ Upgrade_to upgrade_div ]
  | _ -> []


(* ************************************************************************* *)
(* Sets of rules and dates *)
(* ************************************************************************* *)

type rules = rule list

let rules =
  Date.Map.of_seq @@ List.to_seq [

    (* Rules for the beginning/transition period:
       i.e. until the end of 2022 *)
    Date.mk ~day:31 ~month:12 ~year:2022, [
      invited;
      inter_finalist;
      qualifying_finalist;
      auto_promote Intermediate Intermediate;
      auto_promote Advanced Advanced;
      soft_promote Novice 6 Novice_Intermediate;
      hard_promote Novice 12 Intermediate;
      soft_promote Intermediate 24 Intermediate_Advanced;
      hard_promote Intermediate 36 Advanced;
    ];

    (* Rules for the foreseeable future *)
    Date.mk ~day:01 ~month:01 ~year:2100, [
      auto_promote Advanced Advanced;
      auto_promote Intermediate Intermediate;
      soft_promote Novice 6 Novice_Intermediate;
      hard_promote Novice 12 Intermediate;
      soft_promote Intermediate 24 Intermediate_Advanced;
      hard_promote Intermediate 36 Advanced;
    ];

  ]

let get_rules_for date =
  snd @@ Date.Map.find_first (fun d ->
      Date.compare date d <= 0
    ) rules

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
  (* First participants in competition have an all-zero divs,
     and thus it need to be upgraded to at least novice (which will then
     be later upgraded if necessary). *)
  let effective_divs =
    match dancer_divs with
    | None -> Divisions.Novice
    | _ -> dancer_divs
  in
  (* Check that the competitor had access to the competition.
     TODO: add petitions. *)
  if Competition.check_divs competition then begin
    let fail () =
      Logs.err ~src (fun k->
          k "Division check failed for event %a / competition %a:@ \
             %a can only compete in %a"
            Event.print_compact event Competition.print_compact competition
            Dancer.print_compact dancer Divisions.print effective_divs);
      assert false
    in
    match Competition.category competition with
    | Competitive d ->
      if not (Divisions.includes d effective_divs) then fail ()
    | Non_competitive _ -> ()
  end;
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
    List.fold_left (fun divs (rule : rule) ->
        apply divs (rule (Competition.category competition) result points)
      ) effective_divs (get_rules_for (Event.start_date event))
  in
  (* Some logging for promotions.
     TODO: add a DB SQL table to store promotions *)
  if Divisions.equal dancer_divs new_divs then ()
  else begin
    Logs.info ~src (fun k->
        k "PROMOTE : %a %a / %a -> %a@."
          Dancer.print_compact dancer
          Role.print_compact result.role
          Divisions.print effective_divs
          Divisions.print new_divs);
    Dancer.update_divisions ~st ~dancer:id ~role:result.role ~divs:new_divs
  end


