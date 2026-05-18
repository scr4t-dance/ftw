
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Syntax
open! Dream_html
open! Dream_html.HTML


(* ADMIN panel *)
(* ************************************************************************* *)

let judge_link ~st judge =
  let dancer = Ftw.Dancer.get ~st judge in
  a
    [ path_attr href Paths.Page.dancer (Ftw.Dancer.id dancer) ]
    [ txt "%s %s" (Ftw.Dancer.first_name dancer) (Ftw.Dancer.last_name dancer)]

let judge_list ~req:_ ~st l =
  ul [class_ "list-group"] (
    List.map (fun judge ->
      li [class_ "list-group-item"] [
        judge_link ~st judge
      ]
      ) l
  )

let judge_infos ~req ~st ~phase =
  match Ftw.Judge.get ~st ~phase:(Ftw.Phase.id phase) with
  | Singles { head; leaders; followers; } ->
    [
      div [class_ "row"] [
        div [class_ "row py-3"] [
          txt "Head Judge artefacts : %s" (Display.artefact_descr (Ftw.Phase.head_judge_artefact_descr phase));
        ];
        div [class_ "row"] [
          div [class_ "col-6"] [
            judge_list ~req ~st (match head with Some h -> [h] | None -> []);
          ]
        ]
      ];
      div [class_ "row"] [
        div [class_ "row py-3"] [
          txt "Judge artefacts : %s" (Display.artefact_descr (Ftw.Phase.judge_artefact_descr phase));
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
    [path_attr Hx.post Paths.Htmx.phase_regen (Ftw.Phase.id phase); Hx.swap "none"; ]
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
        div [class_ "col-2"] [txt "Pool size"];
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
      let phase = Ftw.Phase.get ~st phase_id in
      let comp = Ftw.Competition.get ~st (Ftw.Phase.competition phase) in
      let ev = Ftw.Event.get ~st (Ftw.Competition.event comp) in
      let$ () = Htmx.ret' ~req ~st ~perms:[Edit_phase {ev;comp;phase}] in
      let heat = Ftw.Heat.get ~st ~phase:(Ftw.Phase.id phase) in 
      Ftw.Heat.regen ~tries:1000 ~st ~phase:(Ftw.Phase.id phase) ~min ~max ~early ~late heat;
      `Trigger "PhaseViewUpdate"
    end
  | _ -> assert false

let phase_start_htmx req phase_id =
  let$ st = State.get req in
  let phase = Ftw.Phase.get ~st phase_id in
  let comp = Ftw.Competition.get ~st (Ftw.Phase.competition phase) in
  let ev = Ftw.Event.get ~st (Ftw.Competition.event comp) in
  let$ () = Htmx.ret' ~req ~st ~perms:[Edit_phase {ev;comp;phase}] in
  let heat = Ftw.Heat.get ~st ~phase:phase_id in
  match heat with
  | Singles { unallocated = _ :: _; _ }
  | Couples { unallocated = _ :: _; _ } ->
    assert false (* TODO: return an error *)
  | _ -> 
    let phase = Ftw.Phase.Private.with_status Progress phase in
    Ftw.Phase.update ~st phase;
    `Refresh

let admin_panel_setup ~req ~st ~ev:_ ~comp:_ ~phase =
  [
    phase_infos ~req ~st ~phase;
    heat_regen_form ~req ~st ~phase;
    button
      [ class_ "btn btn-success"; path_attr Hx.get Paths.Htmx.phase_start (Ftw.Phase.id phase);
        Hx.confirm "Ready ?" ]
      [ txt "Start Heats !" ];
  ]

let admin_panel_progress ~req ~st ~ev:_ ~comp:_ ~phase =
  [
    phase_infos ~req ~st ~phase;
    button
      [ class_ "btn btn-success"; path_attr Hx.get Paths.Htmx.phase_scoring (Ftw.Phase.id phase);
        Hx.confirm "Sure ?" ]
      [ txt "Start Scoring" ];
  ]

let admin_panel_scoring ~req ~st ~ev:_ ~comp:_ ~phase =
  [
    phase_infos ~req ~st ~phase;
    button
      [ class_ "btn btn-success"; path_attr Hx.get Paths.Htmx.phase_finish (Ftw.Phase.id phase);
        Hx.confirm "Sure ?" ]
      [ txt "Finish phase" ];
  ]

let admin_panel ~req ~st ~ev ~comp ~phase =
  if User.check_perms ~req ~st [Edit_phase {ev;comp;phase}] then
   div [class_ "row border border-2 rounded mx-3 my-3 p-2 d-print-none"] (
      h4 [] [txt "Admin panel"] ::
      (match Ftw.Phase.status phase with
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
  let phase = Ftw.Phase.get ~st phase_id in
  let comp = Ftw.Competition.get ~st (Ftw.Phase.competition phase) in
  let ev = Ftw.Event.get ~st (Ftw.Competition.event comp) in
  let$ () =
    Page.mk' ~req ~st
      ~root:(Event [Event {ev}; Comp {comp;}; Phase {phase}])
      ~title:"Phase" ~perms:[View_phase {ev;comp;phase}]
  in
  [
    admin_panel ~req ~st ~ev ~comp ~phase;
    div [class_ "row"] [
      div
        [ path_attr Hx.get Paths.Htmx.phase_view (Ftw.Phase.id phase);
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

let single_heat_table ~req:_ ~st ~bib_map ~role ~passages targets =
  let dancers =
    List.map (fun target_with_id ->
      let target = Ftw.Target.With_id.target target_with_id in
      let Ftw.Target.Single { target = dancer_id; role = _; } = target in
      let dancer = Ftw.Dancer.get ~st dancer_id in
      let bib_opt = Ftw.Bib.TMap.find_opt (Ftw.Target.Any target) bib_map in
      let passage : Ftw.Heat.passage_kind =
        try Ftw.Id.Map.find dancer_id passages
        with Not_found -> Only
      in
      bib_opt, passage, dancer
    ) targets
    |> List.sort (fun (b, _, _) (b', _, _) -> CCOrd.option Ftw.Id.compare b b')
  in
  div [class_ "col-6"] [
    h5 [] [txt "%s" (match (role : Ftw.Role.t) with Leader -> "Leader" | Follower -> "Follower")];
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
            match (passage : Ftw.Heat.passage_kind) with
            | Multiple { nth = 1 } -> "*"
            | _ -> ""
          in
          tr [class_ "%s" (match passage with Multiple {nth} when nth > 1 -> "table-active" | _ -> "")] [
            td [] [txt "#%d" bib];
            td [] [txt "%s%s" (Ftw.Dancer.first_name dancer) star];
            td [] [txt "%s%s" (Ftw.Dancer.last_name dancer) star];
          ]
        | None ->
          tr [] [
            td
              [colspan 3; class_ "text-danger"]
              [txt "Missing bib for %s %s" (Ftw.Dancer.first_name dancer) (Ftw.Dancer.last_name dancer)]
          ]
        ) dancers)
    );
  ]

let single_heat_view ~req ~st ~comp ~phase ~bib_map ~unallocated heats =
  h4 [class_ "text-center"]
    [txt "%s - %s - Pools" (Display.competition_name comp) (Display.round_name phase)] ::
  (match unallocated with
  | [] -> null []
  | _ :: _ ->
    let leaders, followers =
      List.partition (fun single ->
        let role = Ftw.Target.Single.role (Ftw.Target.With_id.target single) in
        match role with Leader -> true | Follower -> false
      ) unallocated
    in
    div [class_ "row py-3 border-bottom"] [
      h4 [class_ "text-center text-danger"] [i [class_ "bi bi-exclamation-circle-fill mx-1"] []; txt "Unallocated"];
      single_heat_table ~req ~st ~bib_map ~passages:Ftw.Id.Map.empty ~role:Leader leaders;
      single_heat_table ~req ~st ~bib_map ~passages:Ftw.Id.Map.empty ~role:Follower followers;
    ]) ::
  List.mapi (fun i (heat : Ftw.Heat.singles_one) ->
    div [class_ "row py-3 border-bottom"] [
      h4 [] [txt "Pool %d" (i + 1)];
      single_heat_table ~req ~st ~bib_map ~passages:heat.passages ~role:Leader heat.leaders;
      single_heat_table ~req ~st ~bib_map ~passages:heat.passages ~role:Follower heat.followers;
      (if Ftw.Id.Map.exists (fun _ passage ->
         match (passage : Ftw.Heat.passage_kind) with
         | Multiple { nth } when nth <= 1 -> true | _ -> false) heat.passages then
        p [] [txt "* : dancers that will dance again in a later pool /\
                       danseurs qui dansent à nouveau dans une future poule"]
      else null []);
    ]
  ) heats

let heat_view ~req ~st ~comp ~phase =
  let bib_map = Ftw.Bib.get_map ~st ~comp in
  let heat = Ftw.Heat.get ~st ~phase:(Ftw.Phase.id phase) in
  match heat with
  | Singles { singles_heats; unallocated; } ->
    let l = Array.to_list singles_heats in
    single_heat_view ~req ~st ~comp ~phase ~bib_map ~unallocated l
  | Couples _ ->
    assert false

let htmx_view req phase_id =
  let$ st = State.get req in
  let phase = Ftw.Phase.get ~st phase_id in
  let comp = Ftw.Competition.get ~st (Ftw.Phase.competition phase) in
  let ev = Ftw.Event.get ~st (Ftw.Competition.event comp) in
  match Ftw.Phase.status phase with
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
    `Body [txt "Scoring..."]
  | Finished ->
    let$ () = Htmx.ret' ~req ~st ~perms:[View_phase {ev;comp;phase}] in
    `Body [txt "Finished"]
