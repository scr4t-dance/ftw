(*
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Syntax
open! Dream_html
open! Dream_html.HTML


(* ADMIN panel *)
(* ************************************************************************* *)

let judge_link ~st judge =
  let dancer = Db.Dancer.get ~st judge in
  a
    [ path_attr href Paths.Page.dancer (Lib.Dancer.id dancer) ]
    [ txt "%s %s" (Lib.Dancer.first_name dancer) (Lib.Dancer.last_name dancer)]

let judge_list ~req:_ ~st l =
  ul [class_ "list-group"] (
    List.map (fun judge ->
      li [class_ "list-group-item"] [
        judge_link ~st judge
      ]
      ) l
  )

let judge_infos ~req ~st ~phase =
  match Db.Judge.get ~st ~phase:(Lib.Phase.id phase) with
  | Singles { head; leaders; followers; } ->
    [
      div [class_ "row"] [
        div [class_ "row py-3"] [
          txt "Head Judge artefacts : %s" (Display.artefact_descr (Lib.Phase.head_judge_artefact_descr phase));
        ];
        div [class_ "row"] [
          div [class_ "col-6"] [
            judge_list ~req ~st (match head with Some h -> [h] | None -> []);
          ]
        ]
      ];
      div [class_ "row"] [
        div [class_ "row py-3"] [
          txt "Judge artefacts : %s" (Display.artefact_descr (Lib.Phase.judge_artefact_descr phase));
        ];
        div [class_ "row"] [
          div [class_ "col-6"] [txt "Leaders"; judge_list ~req ~st leaders];
          div [class_ "col-6"] [txt "Followers"; judge_list ~req ~st followers];
        ];
      ]
    ]
  | Couples { head = _; couples = _; } ->
    []


let phase_infos ~req ~st ~phase =
  div [class_ "row py-3 border-bottom"] (
    [ h5 [] [txt "Infos"] ] @
    ( judge_infos ~req ~st ~phase ) @
    []
  )

let heat_regen_form ~req ~st:_ ~phase =
  form
    [path_attr Hx.post Paths.Htmx.phase_regen (Lib.Phase.id phase); Hx.swap "none"; ]
    [
      csrf_tag req;
      div [class_ "row py-3 border-top"] [
        div [class_ "col-2"] [txt "Early dancers"];
        div [class_ "col-2"] [input [type_ "number"; class_ "form-control"; name "early_n"; value "0"]];
        div [class_ "col-6"] [input [type_ "text"; class_ "form-control"; name "early"; placeholder "1,2,3"]];
      ];
      div [class_ "row py-3"] [
        div [class_ "col-2"] [txt "Late dancers"];
        div [class_ "col-2"] [input [type_ "number"; class_ "form-control"; name "late_n"; value "0"]];
        div [class_ "col-6"] [input [type_ "text"; class_ "form-control"; name "late"; placeholder "1,2,3"]];
      ];
      div [class_ "row py-3 border-bottom"] [
        div [class_ "col-2"] [txt "Heat size"];
        div [class_ "col-2"] [input [type_ "number"; class_ "form-control"; name "min"; placeholder "6"]];
        div [class_ "col-2"] [input [type_ "number"; class_ "form-control"; name "max"; placeholder "10"]];
        div [class_ "col-2"] [button [class_ "btn btn-primary"; type_ "submit"] [txt "Generate Heats"]];
      ]
    ]

let dancer_list_parser s =
  try
    Ok (
      String.split_on_char ',' s
      |> List.map String.trim
      |> List.filter (fun s -> String.length s > 0)
      |> List.map int_of_string)
  with Failure _ -> Error "not an int"

let heat_regen_form_validator =
  let open Form in
  let* min = required (int ~min:0) "min" in
  let+ early_n = required ~default:0 (int ~min:0) "early_n"
  and+ early_d = required dancer_list_parser "early"
  and+ late_n = required ~default:0 (int ~min:0) "late_n"
  and+ late_d = required dancer_list_parser "late"
  and+ max = required (int ~min) "max"
  in
  (min, max, (early_n, early_d), (late_n, late_d))

let heat_regen_htmx req phase_id =
  match%lwt Dream.form req with
  | `Ok form_result ->
    begin match Form.validate heat_regen_form_validator form_result with
    | Error errs ->
      List.iter (fun (field, msg) ->
          Logs.err (fun k->k "Error while decoding form field %s: %s" field msg)
        ) errs;
      assert false (* internal error, or incorrect api usage from external source *)
    | Ok (min, max, early, late) ->
      let$ st = State.get req in
      let phase = Db.Phase.get ~st phase_id in
      let comp = Db.Competition.get ~st (Lib.Phase.competition phase) in
      let ev = Db.Event.get ~st (Lib.Competition.event comp) in
      let$ () = Htmx.ret' ~req ~st ~perms:[Edit_phase {ev;comp;phase}] in
      let heat = Db.Heat.get ~st ~phase:(Lib.Phase.id phase) in
      begin match Lib.Competition.kind comp, Lib.Phase.round phase with
        | Jack_and_Jill, _ ->
          let forbidden_pairs = Db.Forbidden.get ~st ~event:(Lib.Event.id ev) in
          Db.Heat.regen_singles ~tries:1000 ~st ~phase:(Lib.Phase.id phase) ~forbidden_pairs ~min ~max ~early ~late heat;
          `Trigger "PhaseViewUpdate"
        | High_low _, Prelims ->
          let forbidden_pairs = Db.Forbidden.get ~st ~event:(Lib.Event.id ev) in
          Db.Heat.regen_singles ~tries:1000 ~st ~phase:(Lib.Phase.id phase) ~forbidden_pairs ~min ~max ~early ~late heat;
          `Trigger "PhaseViewUpdate"
        | High_low _, _ ->
          Db.Heat.regen_couples ~tries:1000 ~st ~phase:(Lib.Phase.id phase) ~min ~max ~early ~late heat;
          `Trigger "PhaseViewUpdate"
        | Strictly, _ ->
          Db.Heat.regen_couples ~tries:100 ~st ~phase:(Lib.Phase.id phase) ~min ~max ~early ~late heat;
          `Trigger "PhaseViewUpdate"
        | _ ->
          assert false
      end
    end
  | _ -> assert false

let one_heat_pairing_form ~req:_ ~st ~bib_map i (heat : Lib.Heat.one) =
  match heat.leaders, heat.followers, heat.couples with
  | [], [], [] -> null []
  | leaders, followers, _ ->
    let n_l = List.length leaders in
    let n_f = List.length followers in

    if n_l = 0 && n_f = 0 then begin
      null []
    end else if n_l = 0 then begin
      let leader_options =
        List.map (fun couple_target ->
          let leader_id = Lib.Target.With_id.target couple_target |> Lib.Target.Couple.leader in
          let leader = Db.Dancer.get ~st leader_id in
          let bib = Option.get @@ Db.Bib.TMap.find_opt (Lib.Target.(Any (Single { target = leader_id; role = Leader }))) bib_map in
          bib, leader_id, leader
          ) heat.couples
        |> List.sort (fun (b, _, _) (b', _, _) -> Lib.Id.compare b b')
        |> List.map (fun (bib, leader_id, leader) ->
            option [value "%d" leader_id] "#%d - %s %s" bib (Lib.Dancer.first_name leader) (Lib.Dancer.last_name leader)) 
      in
      div [class_ "row"] [
        h5 [] [txt "Heat %d" i];
        table [] (
        List.map (fun follower_target ->
          let follower_target_id = Lib.Target.With_id.id follower_target in
          let follower_target = Lib.Target.With_id.target follower_target in
          let follower = Db.Dancer.get ~st (Lib.Target.Single.dancer follower_target) in
          let bib = Option.get @@ Db.Bib.TMap.find_opt (Lib.Target.Any follower_target) bib_map in
          bib, follower_target_id, follower
        ) followers
        |> List.sort (fun (b, _, _) (b', _, _) -> Lib.Id.compare b b')
        |> List.map (fun (bib, follower_target_id, follower) ->
          tr [] [
            td [] [
              select 
               [class_ "form-select"; name "follower-%d-%d" follower_target_id i;]
               (option [value "0"] "--" :: leader_options)
            ];
            td [] [txt "#%d - %s %s" bib (Lib.Dancer.first_name follower) (Lib.Dancer.last_name follower)];
          ])
        )
      ]
    end else if n_f = 0 then begin
      let follow_options =
        List.map (fun couple_target ->
          let follower_id = Lib.Target.With_id.target couple_target |> Lib.Target.Couple.follower in
          let follower = Db.Dancer.get ~st follower_id in
          let bib = Option.get @@ Db.Bib.TMap.find_opt (Lib.Target.(Any (Single { target = follower_id; role = Follower }))) bib_map in
          bib, follower_id, follower
          ) heat.couples
        |> List.sort (fun (b, _, _) (b', _, _) -> Lib.Id.compare b b')
        |> List.map (fun (bib, follow_id, follower) ->
            option [value "%d" follow_id] "#%d - %s %s" bib (Lib.Dancer.first_name follower) (Lib.Dancer.last_name follower)) 
      in
      div [class_ "row"] [
        h5 [] [txt "Heat %d" i];
        table [] (
        List.map (fun leader_target ->
          let leader_target_id = Lib.Target.With_id.id leader_target in
          let leader_target = Lib.Target.With_id.target leader_target in
          let leader = Db.Dancer.get ~st (Lib.Target.Single.dancer leader_target) in
          let bib = Option.get @@ Db.Bib.TMap.find_opt (Lib.Target.Any leader_target) bib_map in
          bib, leader_target_id, leader
        ) leaders
        |> List.sort (fun (b, _, _) (b', _, _) -> Lib.Id.compare b b')
        |> List.map (fun (bib, leader_target_id, leader) ->
          tr [] [
            td [] [txt "#%d - %s %s" bib (Lib.Dancer.first_name leader) (Lib.Dancer.last_name leader)];
            td [] [
              select 
               [class_ "form-select"; name "leader-%d-%d" leader_target_id i;]
               (option [value "0"] "--" :: follow_options)
            ];
          ])
        )
      ]
    end else begin
      let follow_options =
        List.map (fun follower_target ->
          let follow_target_id = Lib.Target.With_id.id follower_target in
          let follower_target = Lib.Target.With_id.target follower_target in
          let follower = Db.Dancer.get ~st (Lib.Target.Single.dancer follower_target) in
          let bib = Option.get @@ Db.Bib.TMap.find_opt (Lib.Target.Any follower_target) bib_map in
          bib, follow_target_id, follower
          ) followers
        |> List.sort (fun (b, _, _) (b', _, _) -> Lib.Id.compare b b')
        |> List.map (fun (bib, follow_target_id, follower) ->
            option [value "%d" follow_target_id] "#%d - %s %s" bib (Lib.Dancer.first_name follower) (Lib.Dancer.last_name follower)) 
      in
      div [class_ "row"] [
        h5 [] [txt "Heat %d" i];
        table [] (
        List.map (fun leader_target ->
          let leader_target_id = Lib.Target.With_id.id leader_target in
          let leader_target = Lib.Target.With_id.target leader_target in
          let leader = Db.Dancer.get ~st (Lib.Target.Single.dancer leader_target) in
          let bib = Option.get @@ Db.Bib.TMap.find_opt (Lib.Target.Any leader_target) bib_map in
          bib, leader_target_id, leader
        ) leaders
        |> List.sort (fun (b, _, _) (b', _, _) -> Lib.Id.compare b b')
        |> List.map (fun (bib, leader_target_id, leader) ->
          tr [] [
            td [] [txt "#%d - %s %s" bib (Lib.Dancer.first_name leader) (Lib.Dancer.last_name leader)];
            td [] [
              select 
               [class_ "form-select"; name "pair-%d-%d" leader_target_id i;]
               (option [value "0"] "--" :: follow_options)
            ];
          ])
        )
      ]
    end

let heat_pairing_form ~req ~st ~comp ~phase =
  let Regular heats = Db.Heat.get ~st ~phase:(Lib.Phase.id phase) in
  let bib_map = Db.Bib.get_map ~st ~comp in
  form
    [path_attr Hx.post Paths.Htmx.phase_pairing (Lib.Phase.id phase); Hx.swap "none"; ]
    (
      csrf_tag req ::
      List.mapi (one_heat_pairing_form ~req ~st ~bib_map) (heats.unallocated :: Array.to_list heats.heats)
      @ [
        div [class_ "row m-3 py-2"] [button [class_ "btn btn-primary"; type_ "submit"] [txt "Save pairings"]]
      ]
    )

let extract_target_single_dancer_id ~st target_id =
  match Db.Heat.get_one ~st target_id with
  | Any Single { target; role = _; } -> target
  | _ -> assert false

let heat_pair_htmx req phase_id =
  match%lwt Dream.form req with
  | `Ok form_results ->
    let$ st = State.get req in
    let phase = Db.Phase.get ~st phase_id in
    let comp = Db.Competition.get ~st (Lib.Phase.competition phase) in
    let ev = Db.Event.get ~st (Lib.Competition.event comp) in
    let$ () = Htmx.ret' ~req ~st ~perms:[Edit_phase {ev;comp;phase}] in
    List.iter (fun (form_field, form_value) ->
      match String.split_on_char '-' form_field with
      | ["pair"; leader_target_id; heat] ->
        let heat = int_of_string heat in
        let leader_target_id = int_of_string leader_target_id in
        let follow_target_id = int_of_string form_value in
        if follow_target_id = 0 then ()
        else begin
          Logs.debug (fun k->k "Pairing %d - %d" leader_target_id follow_target_id);
          let leader = extract_target_single_dancer_id ~st leader_target_id in
          let follower = extract_target_single_dancer_id ~st follow_target_id in
          Db.Heat.delete_one ~st leader_target_id;
          Db.Heat.delete_one ~st follow_target_id;
          let _ =
            Db.Heat.add_couple
              ~st ~phase:(Lib.Phase.id phase)
              ~heat ~leader ~follower
          in
          ()
        end
      | ["leader"; leader_target_id; heat] ->
        let heat = int_of_string heat in
        let leader_target_id = int_of_string leader_target_id in
        let follower = int_of_string form_value in
        if follower = 0 then ()
        else begin
          let leader = extract_target_single_dancer_id ~st leader_target_id in
          Db.Heat.delete_one ~st leader_target_id;
          let _ =
            Db.Heat.add_couple
              ~st ~phase:(Lib.Phase.id phase)
              ~heat ~leader ~follower
          in
          ()
        end
      | ["follower"; follower_target_id; heat] ->
        let heat = int_of_string heat in
        let follower_target_id = int_of_string follower_target_id in
        let leader = int_of_string form_value in
        if leader = 0 then ()
        else begin
          let follower = extract_target_single_dancer_id ~st follower_target_id in
          Db.Heat.delete_one ~st follower_target_id;
          let _ =
            Db.Heat.add_couple
              ~st ~phase:(Lib.Phase.id phase)
              ~heat ~leader ~follower
          in
          ()
        end
      | _ -> ()
      ) form_results;
    `Refresh
  | _ -> assert false



let phase_start_htmx req phase_id =
  let$ st = State.get req in
  let phase = Db.Phase.get ~st phase_id in
  let comp = Db.Competition.get ~st (Lib.Phase.competition phase) in
  let ev = Db.Event.get ~st (Lib.Competition.event comp) in
  let$ () = Htmx.ret' ~req ~st ~perms:[Edit_phase {ev;comp;phase}] in
  let heat = Db.Heat.get ~st ~phase:phase_id in
  match heat with
  | Regular { unallocated = { leaders = _ :: _ ; _ }; _ }
  | Regular { unallocated = { followers = _ :: _ ; _ }; _ }
  | Regular { unallocated = { couples = _ :: _ ; _ }; _ } ->
    assert false (* TODO: return an error *)
  | _ -> 
    let phase = Lib.Phase.Private.with_status Progress phase in
    Db.Phase.update ~st phase;
    `Refresh

let phase_score_htmx req phase_id =
  let$ st = State.get req in
  let phase = Db.Phase.get ~st phase_id in
  let comp = Db.Competition.get ~st (Lib.Phase.competition phase) in
  let ev = Db.Event.get ~st (Lib.Competition.event comp) in
  let$ () = Htmx.ret' ~req ~st ~perms:[Edit_phase {ev;comp;phase}] in
  let phase = Lib.Phase.Private.with_status Scoring phase in
  Db.Phase.update ~st phase;
  `Refresh

let phase_finish_htmx req phase_id =
  let$ st = State.get req in
  let phase = Db.Phase.get ~st phase_id in
  let comp = Db.Competition.get ~st (Lib.Phase.competition phase) in
  let ev = Db.Event.get ~st (Lib.Competition.event comp) in
  let$ () = Htmx.ret' ~req ~st ~perms:[Edit_comp {ev;comp}] in
  match Lib.Phase.round phase with
  | Finals -> assert false
  | _ ->
    let next_round, n = Lib.Competition.next_round comp (Some (Lib.Phase.round phase)) in
    let next_phase = Option.get @@ Db.Competition.round ~st comp next_round in
    let ranking = Db.Phase.ranking ~st ~phase in
    begin match Db.Phase.targets_in_range ranking (Lib.Rank.mk 1) (Lib.Rank.mk n) with
    | None -> assert false
    | Some promoted_target_ids ->
      let promoted_targets = List.map (Db.Heat.get_one ~st) promoted_target_ids in
      let _ = Db.Heat.init ~st ~phase:next_phase promoted_targets in
      let next_phase = Lib.Phase.Private.with_status Setup next_phase in
      let phase = Lib.Phase.Private.with_status Finished phase in
      Db.Phase.update ~st next_phase;
      Db.Phase.update ~st phase;
      (* TODO: redirect toward the new pahse webpage *)
      `Refresh
    end


let admin_panel_setup ~req ~st ~ev:_ ~comp:_ ~phase =
  [
    phase_infos ~req ~st ~phase;
    heat_regen_form ~req ~st ~phase;
    button
      [ class_ "btn btn-success"; path_attr Hx.get Paths.Htmx.phase_start (Lib.Phase.id phase);
        Hx.confirm "Ready ?" ]
      [ txt "Start Heats !" ];
  ]

let admin_panel_progress ~req ~st ~ev:_ ~comp ~phase =
  [
    phase_infos ~req ~st ~phase;
    (match Lib.Competition.kind comp, Lib.Phase.round phase with
      | Jack_and_Jill, Finals
      | High_low _, Prelims ->
        heat_pairing_form ~req ~st ~comp ~phase
      | _ -> null []
    );
    div [class_ "row"] [
        button
          [ class_ "btn btn-success m-3"; path_attr Hx.get Paths.Htmx.phase_scoring (Lib.Phase.id phase);
            Hx.confirm "Sure ?" ]
          [ txt "Start Scoring" ];
    ];
  ]

let admin_panel_scoring ~req ~st ~ev:_ ~comp:_ ~phase =
  [
    phase_infos ~req ~st ~phase;
    button
      [ class_ "btn btn-success"; path_attr Hx.get Paths.Htmx.phase_finish (Lib.Phase.id phase);
        Hx.confirm "Sure ?" ]
      [ txt "Finish phase" ];
  ]

let admin_panel ~req ~st ~ev ~comp ~phase =
  if User.check_perms ~req ~st [Edit_phase {ev;comp;phase}] then
   div [class_ "row border border-2 rounded mx-3 my-3 p-2 d-print-none"] (
      h4 [] [txt "Admin panel"] ::
      (match Lib.Phase.status phase with
      | Inactive -> []
      | Setup -> admin_panel_setup ~req ~st ~ev ~comp ~phase
      | Progress -> admin_panel_progress ~req ~st ~ev ~comp ~phase
      | Scoring -> admin_panel_scoring ~req ~st ~ev ~comp ~phase
      | Finished -> []
      )
   )
  else
    null []


(* Main page *)
(* ************************************************************************* *)

let page req phase_id =
  let$ st = State.get req in
  let phase = Db.Phase.get ~st phase_id in
  let comp = Db.Competition.get ~st (Lib.Phase.competition phase) in
  let ev = Db.Event.get ~st (Lib.Competition.event comp) in
  let$ () =
    Page.mk' ~req ~st
      ~root:(Event [Event {ev}; Comp {comp;}; Phase {phase}])
      ~title:"Phase" ~perms:[View_phase {ev;comp;phase}]
  in
  [
    admin_panel ~req ~st ~ev ~comp ~phase;
    div [class_ "row"] [
      div
        [ path_attr Hx.get Paths.Htmx.phase_view (Lib.Phase.id phase);
          Hx.swap "innerHTML"; Hx.trigger "intersect, PhaseViewUpdate from:body";]
        [
          div [class_ "spinnner spinner-border"; role `status] [
            span [class_ "visually-hidden"] [txt "Loading..."]
          ]
        ]
    ]
  ]


(* Htmx view *)
(* ************************************************************************* *)

let heat_table_singles ~req:_ ~st ~bib_map ~role ~passages targets =
  let dancers =
    List.map (fun target_with_id ->
      let target = Lib.Target.With_id.target target_with_id in
      let Lib.Target.Single { target = dancer_id; role = _; } = target in
      let dancer = Db.Dancer.get ~st dancer_id in
      let bib_opt = Db.Bib.TMap.find_opt (Lib.Target.Any target) bib_map in
      let passage : Lib.Heat.passage_kind =
        try Lib.Id.Map.find dancer_id passages
        with Not_found -> Only
      in
      bib_opt, passage, dancer
    ) targets
    |> List.sort (fun (b, _, _) (b', _, _) -> CCOrd.option Lib.Id.compare b b')
  in
  div [class_ "col-6"] [
    h5 [] [txt "%s" (match (role : Lib.Role.t) with Leader -> "Leader" | Follower -> "Follower")];
    table [class_ "table table-hover"] (
      thead [] [
        tr [] [
          th [] [txt "#"];
          th [] [txt "First Name"];
          th [] [txt "Last Name"];
        ];
      ] ::
      (List.map (fun (bib_opt, passage, dancer) ->
        match bib_opt with
        | Some bib ->
          let star =
            match (passage : Lib.Heat.passage_kind) with
            | Multiple { nth = 1 } -> "*"
            | _ -> ""
          in
          tr [class_ "%s" (match passage with Multiple {nth} when nth > 1 -> "table-active" | _ -> "")] [
            td [] [txt "#%d" bib];
            td [] [txt "%s%s" (Lib.Dancer.first_name dancer) star];
            td [] [txt "%s%s" (Lib.Dancer.last_name dancer) star];
          ]
        | None ->
          tr [] [
            td
              [colspan 3; class_ "text-danger"]
              [txt "Missing bib for %s %s" (Lib.Dancer.first_name dancer) (Lib.Dancer.last_name dancer)]
          ]
        ) dancers)
    );
  ]

let heat_table_couples ~req:_ ~st ~bib_map targets =
  let couples =
    List.map (fun target_with_id ->
      let target = Lib.Target.With_id.target target_with_id in
      let Lib.Target.Couple { leader; follower; } = target in

      let leader_bib_opt, follower_bib_opt =
        match Db.Bib.TMap.find_opt (Any target) bib_map with
        | None ->
          let leader_bib_opt = Db.Bib.TMap.find_opt (Lib.Target.Any (Single { target = leader; role = Leader; })) bib_map in
          let follower_bib_opt = Db.Bib.TMap.find_opt (Lib.Target.Any (Single { target = follower; role = Follower; })) bib_map in
          leader_bib_opt, follower_bib_opt
        | Some _bib as bib_opt ->
          bib_opt, bib_opt
        in

      let leader = Db.Dancer.get ~st leader in
      let follower = Db.Dancer.get ~st follower in
      leader_bib_opt, leader, follower_bib_opt, follower
    ) targets
    |> List.sort (fun (b, _, _, _) (b', _, _, _) -> CCOrd.option Lib.Id.compare b b')
  in
  div [class_ "col-12"] [
    h5 [] [txt "Couples"];
    table [class_ "table table-hover"] (
      thead [] [
        tr [] [
          th [] [txt "#"];
          th [] [txt "Leader"];
          th [] [txt "#"];
          th [] [txt "Follower"];
        ];
      ] ::
      (List.map (fun (leader_bib_opt, leader, follower_bib_opt, follower) ->
        match leader_bib_opt, follower_bib_opt with
        | Some lbib, Some fbib ->
          tr [] [
            td [] [txt "#%d" lbib];
            td [] [txt "%s %s" (Lib.Dancer.first_name leader) (Lib.Dancer.last_name leader)];
            td [] [txt "#%d" fbib];
            td [] [txt "%s %s" (Lib.Dancer.first_name follower) (Lib.Dancer.last_name follower)];
          ]
        | _ ->
          tr [] [
            td
              [colspan 3; class_ "text-danger"]
              [txt "Missing bib for %s %s & %s %s"
                (Lib.Dancer.first_name leader) (Lib.Dancer.last_name leader)
                (Lib.Dancer.first_name follower) (Lib.Dancer.last_name follower)]
          ]
        ) couples)
    );
  ]


let one_heat_view ~req ~st ~bib_map ~i (heat : Lib.Heat.one) =
  match heat.leaders, heat.followers, heat.couples with
  | [], [], [] -> null []
  | _ ->
    div [class_ "row py-3 border-bottom"] [
      (if i = 0 then
        h4
          [class_ "text-center text-danger"]
          [Dream_html.HTML.i [class_ "bi bi-exclamation-circle-fill"] []; txt "Unallocated"]
      else
        h4 [] [txt "Heat %d" i]
      );

      (match heat.leaders, heat.followers with
      | [], [] -> null []
      | _, _ ->
        div [class_ "row"] [
          heat_table_singles ~req ~st ~bib_map ~passages:heat.passages ~role:Leader heat.leaders;
          heat_table_singles ~req ~st ~bib_map ~passages:heat.passages ~role:Follower heat.followers;
        ]);

      (match heat.couples with 
        | [] -> null []
        | _ ->
          div [class_ "row"] [
            heat_table_couples ~req ~st ~bib_map heat.couples;
          ]
      );

      (if Lib.Id.Map.exists (fun _ passage ->
          match (passage : Lib.Heat.passage_kind) with
          | Multiple { nth } when nth <= 1 -> true | _ -> false) heat.passages then
        p [] [txt "* : dancers that will dance again in a later pool /\
                        danseurs qui dansent à nouveau dans une future poule"]
      else null []);
    ]

let regular_heat_view ~req ~st ~comp ~phase ~bib_map ~unallocated heats =
  h4 [class_ "text-center"]
    [txt "%s - %s - Heats" (Display.competition_name comp) (Display.round_name phase)] ::
  List.mapi (fun i (heat : Lib.Heat.one) ->
    one_heat_view ~req ~st ~bib_map ~i heat
  ) (unallocated :: heats)

let heat_view ~req ~st ~comp ~phase =
  let bib_map = Db.Bib.get_map ~st ~comp in
  let heat = Db.Heat.get ~st ~phase:(Lib.Phase.id phase) in
  match heat with
  | Regular { heats; unallocated; } ->
    let l = Array.to_list heats in
    regular_heat_view ~req ~st ~comp ~phase ~bib_map ~unallocated l

let htmx_view req phase_id =
  let$ st = State.get req in
  let phase = Db.Phase.get ~st phase_id in
  let comp = Db.Competition.get ~st (Lib.Phase.competition phase) in
  let ev = Db.Event.get ~st (Lib.Competition.event comp) in
  match Lib.Phase.status phase with
  | Inactive ->
    let$ () = Htmx.ret' ~req ~st ~perms:[View_phase {ev;comp;phase}] in
    `Body [txt "Inactive"]
  | Setup ->
    let$ () = Htmx.ret' ~req ~st ~perms:[View_phase {ev;comp;phase}] in
    `Body (heat_view ~req ~st ~comp ~phase)
  | Progress ->
    let$ () = Htmx.ret' ~req ~st ~perms:[View_phase {ev;comp;phase}] in
    `Body (heat_view ~req ~st ~comp ~phase)
  | Scoring ->
    let$ () = Htmx.ret' ~req ~st ~perms:[View_phase {ev;comp;phase}] in
    `Body [
        div
          [ path_attr Hx.get Paths.Htmx.artefacts_view (Lib.Phase.id phase);
            Hx.swap "innerHTML"; Hx.trigger "revealed once";]
          [
            div [class_ "spinnner spinner-border"; role `status] [
              span [class_ "visually-hidden"] [txt "Loading..."]
            ]
          ]
        ]
  | Finished ->
    let$ () = Htmx.ret' ~req ~st ~perms:[View_phase {ev;comp;phase}] in
    `Body [
        div
          [ path_attr Hx.get Paths.Htmx.artefacts_view (Lib.Phase.id phase);
            Hx.swap "innerHTML"; Hx.trigger "revealed once";]
          [
            div [class_ "spinnner spinner-border"; role `status] [
              span [class_ "visually-hidden"] [txt "Loading..."]
            ]
          ]
        ]
*)
