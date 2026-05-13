
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Syntax
open! Dream_html
open! Dream_html.HTML


(* Display functions *)
(* ************************************************************************* *)

let round_to_string round =
  match (round : Ftw.Round.t) with
  | Prelims -> "Prelims"
  | Finals -> "Finals"
  | Semifinals -> "Semifinals"
  | Quarterfinals -> "Quarterfinals"
  | Octofinals -> "Octofinals"

let round_name phase =
  round_to_string (Ftw.Phase.round phase)

let display_status phase =
  match Ftw.Phase.status phase with
  | Inactive -> "Inactive"
  | Setup -> "Setup"
  | Progress -> "Progress"
  | Scoring -> "Scoring"
  | Finished -> "Finished"


(* ADMIN panel *)
(* ************************************************************************* *)

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

let admin_panel_setup ~req ~st ~ev:_ ~comp:_ ~phase =
  [
    heat_regen_form ~req ~st ~phase;
    button
      [ class_ "btn btn-success"; path_attr Hx.get Paths.Htmx.phase_start (Ftw.Phase.id phase);
        Hx.confirm "Ready ?" ]
      [ txt "Start Heats !" ];
  ]

let htmx_start _req _phase_id =
  assert false

let admin_panel ~req ~st ~ev ~comp ~phase =
  if User.check_perms ~req ~st [Edit_phase {ev;comp;phase}] then
   div [class_ "row border border-2 rounded mx-3 my-3 p-2"] (
      h4 [] [txt "Admin panel"] ::
      (match Ftw.Phase.status phase with
      | Inactive -> []
      | Setup -> admin_panel_setup ~req ~st ~ev ~comp ~phase
      | Progress -> []
      | Scoring -> []
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
  let$ () = Page.mk' ~req ~st ~root:Event ~title:"Phase" ~perms:[View_phase {ev;comp;phase}] in
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

let single_heat_table ~req:_ ~st ~bib_map ~role targets =
  let dancers =
    List.map (fun target_with_id ->
      let target = Ftw.Target.With_id.target target_with_id in
      let Ftw.Target.Single { target = dancer_id; role = _; } = target in
      let dancer = Ftw.Dancer.get ~st dancer_id in
      let bib_opt = Ftw.Bib.TMap.find_opt (Ftw.Target.Any target) bib_map in
      bib_opt, dancer
    ) targets
    |> List.sort (fun (b, _) (b', _) -> CCOrd.option Ftw.Id.compare b b')
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
      (List.map (fun (bib_opt, dancer) ->
        match bib_opt with
        | Some bib ->
          tr [] [
            td [] [txt "#%d" bib];
            td [] [txt "%s" (Ftw.Dancer.first_name dancer)];
            td [] [txt "%s" (Ftw.Dancer.last_name dancer)];
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

let single_heat_view ~req ~st ~bib_map ~unallocated heats =
  h4 [class_ "text-center"] [txt "Pools"] ::
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
      single_heat_table ~req ~st ~bib_map ~role:Leader leaders;
      single_heat_table ~req ~st ~bib_map ~role:Follower followers;
    ]) ::
  List.mapi (fun i (heat : Ftw.Heat.singles_one) ->
    div [class_ "row py-3 border-bottom"] [
      h4 [] [txt "Pool %d" (i + 1)];
      single_heat_table ~req ~st ~bib_map ~role:Leader heat.leaders;
      single_heat_table ~req ~st ~bib_map ~role:Follower heat.followers;
    ]
  ) heats

let heat_view ~req ~st ~comp ~phase =
  let bib_map = Ftw.Bib.get_map ~st ~comp in
  let heat = Ftw.Heat.get ~st ~phase:(Ftw.Phase.id phase) in
  match heat with
  | Singles { singles_heats; unallocated; } ->
    let l = Array.to_list singles_heats in
    single_heat_view ~req ~st ~bib_map ~unallocated l
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
    `Body [txt "In progress..."]
  | Scoring ->
    let$ () = Htmx.ret' ~req ~st ~perms:[View_phase {ev;comp;phase}] in
    `Body [txt "Scoring..."]
  | Finished ->
    let$ () = Htmx.ret' ~req ~st ~perms:[View_phase {ev;comp;phase}] in
    `Body [txt "Finished"]
