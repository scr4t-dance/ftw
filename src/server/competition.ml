
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Syntax
open! Dream_html
open Dream_html.HTML


(* Admin panel *)
(* ************************************************************************* *)

let comp_infos ~req ~st ?(judges=false) comp =
  div [class_ "row py-3"] [
    h5 [] [txt "Infos"];
    div [class_ "row"] [
      div [class_ "col"] [
        txt "Kind: %s" (Display.kind (Ftw.Competition.kind comp));
      ];
      div [class_ "col"] [
       txt "Category: %s" (Display.category (Ftw.Competition.category comp));
      ];
      div [class_ "col"] [
        txt "Status: %s" (Display.comp_status comp);
      ];
    ];
    if judges then
      div [class_ "row border-top border-2 my-2 py-2"] (
        [ h5 [] [txt "Prelims"] ] @ (
        match Ftw.Competition.round ~st comp Prelims with
        | None -> []
        | Some prelims -> Phase.judge_infos ~req ~st ~phase:prelims
        )
      )
    else null [];
    if judges then
      div [class_ "row border-top border-2 my-2 py-2"] (
        [ h5 [] [txt "Finals"] ] @ (
        match Ftw.Competition.round ~st comp Finals with
        | None -> []
        | Some prelims -> Phase.judge_infos ~req ~st ~phase:prelims
        )
      )
    else null [];
  ]

let count_bibs ~st ~comp =
  let bibs = Ftw.Bib.get_all ~st ~competition:(Ftw.Competition.id comp) in
  let n_leaders, n_followers =
    List.fold_left (fun (n_l, n_f) (_bib, target) ->
      match (target : _ Ftw.Target.any) with
      | Any Single { target = _; role = Leader; } -> (n_l + 1, n_f)
      | Any Single { target = _; role = Follower; } -> (n_l, n_f + 1)
      | _ -> Logs.err (fun k->k "unexpected target !"); n_l, n_f
    ) (0,0) bibs
  in
  n_leaders, n_followers

let htmx_distrib req comp_id =
  let$ st = State.get req in
  let comp = Ftw.Competition.get ~st comp_id in
  let ev = Ftw.Event.get ~st (Ftw.Competition.event comp) in
  let$ () = Htmx.ret' ~req ~st ~perms:[Edit_comp {ev;comp}] in
  match Ftw.Competition.status comp with
  | Registration ->
    let comp = Ftw.Competition.Private.with_status Distribution comp in
    Ftw.Competition.update ~st comp;
    `Refresh
  | _ -> assert false

let htmx_start req comp_id =
  let$ st = State.get req in
  let comp = Ftw.Competition.get ~st comp_id in
  let ev = Ftw.Event.get ~st (Ftw.Competition.event comp) in
  let$ () = Htmx.ret' ~req ~st ~perms:[Edit_comp {ev;comp}] in
  match Ftw.Competition.status comp with
  | Distribution ->
    let comp = Ftw.Competition.Private.with_status Progress comp in
    let bibs = Ftw.Bib.get_all ~st ~competition:(Ftw.Competition.id comp) in
    let targets = List.map snd bibs in
    (* TODO: handle strictlys *)
    let n_leaders, n_follows =
      List.fold_left (fun (n_l, n_f) target ->
        match (target : _ Ftw.Target.any) with
        | Any Single { role = Leader; _ } -> (n_l + 1, n_f)
        | Any Single { role = Follower; _ } -> (n_l, n_f + 1)
        | _ -> n_l, n_f) (0,0) targets
    in
    let comp = Ftw.Competition.Private.with_n ~leaders:n_leaders ~followers:n_follows comp in
    let n = Ftw.Competition.round_count comp Prelims in
    let round : Ftw.Round.t =
      if n <> 0 then Prelims
      else begin
        (match Ftw.Competition.round ~st comp Prelims with
        | Some prelims ->
          Ftw.Judge.clear ~st ~phase:(Ftw.Phase.id prelims);
          Ftw.Phase.delete ~st (Ftw.Phase.id prelims)
        | None -> ());
        Finals
      end
    in
    begin match Ftw.Competition.round ~st comp round with
      | Some prelims ->
        assert (Ftw.Phase.status prelims = Ftw.Phase.Inactive);
        let prelims = Ftw.Phase.Private.with_status Setup prelims in
        let _ = Ftw.Heat.init ~st ~phase:prelims targets in
        Ftw.Competition.update ~st comp;
        Ftw.Phase.update ~st prelims;
        `Refresh
      | None -> assert false
    end
  | _ -> assert false

let phase_item_status phase =
  match Ftw.Phase.status phase with
  | Inactive -> "list-group-item-dark"
  | Setup -> "list-group-item-warning"
  | Progress -> "list-group-item-primary"
  | Scoring -> "list-group-item-danger"
  | Finished -> "list-group-item-success"

let admin_panel_setup ~req ~st ~ev:_ ~comp =
  [
    comp_infos ~judges:true ~req ~st comp;
  ]

let admin_panel_registration ~req ~st ~ev:_ ~comp =
  [
    comp_infos ~req ~st comp;
    button
      [ class_ "btn btn-success"; path_attr Hx.get Paths.Htmx.comp_distrib (Ftw.Competition.id comp);
        Hx.confirm "Ready ?" ]
      [ txt "Start Bib Distribution !" ];
  ]

let admin_panel_distrib ~req ~st ~ev:_ ~comp =
  let n_leaders, n_followers = count_bibs ~st ~comp in
  [
    comp_infos ~req ~st comp;
    div [class_ "row border-top border-2 my-2 py-2"] [
      h5 [] [txt "Bib Count"];
      div [class_ "col"] [
        txt "Leaders : %d" n_leaders;
      ];
      div [class_ "col"] [
        txt "Followers : %d" n_followers;
      ];
    ];
    div [class_ "row px-2 py-2"] [
      button [ class_ "btn btn-primary mx-3";
               path_attr Hx.get Paths.Htmx.comp_start (Ftw.Competition.id comp);
               Hx.confirm "Confirm competition start (after the start, no new bibs may be added)"; ]
      [txt "Start Competition !"]
    ];
  ]

let admin_panel_progress ~req ~st ~ev:_ ~comp =
  let phases = Ftw.Competition.phases ~st comp in
  [
    comp_infos ~req ~st comp;
    ul [class_ "list-group"] (
      List.map (fun phase ->
        li [class_ "list-group-item %s" (phase_item_status phase)] [
          a
            [path_attr href Paths.Page.phase (Ftw.Phase.id phase)]
            [txt "%s - %s" (Display.round_name phase) (Display.phase_status phase)];
        ]
      ) phases
    )
  ]

let admin_panel ~req ~st ~ev ~comp =
  if User.check_perms ~req ~st [Edit_comp {ev;comp}] then
   div [class_ "row border border-2 rounded mx-3 my-3 p-2 d-print-none"] (
      h4 [] [txt "Admin panel"] ::
      (match Ftw.Competition.status comp with
      | Setup -> admin_panel_setup ~req ~st ~ev ~comp;
      | Registration -> admin_panel_registration ~req ~st ~ev ~comp
      | Distribution -> admin_panel_distrib ~req ~st ~ev ~comp
      | Progress -> admin_panel_progress ~req ~st ~ev ~comp
      | Finished -> [])
   )
  else
    null []


(* Main page *)
(* ************************************************************************* *)

let page req comp_id =
  let$ st = State.get req in
  let comp = Ftw.Competition.get ~st comp_id in
  let ev = Ftw.Event.get ~st (Ftw.Competition.event comp) in
  let$ () =
    Page.mk' ~req ~st
      ~root:(Event [Event {ev}; Comp {comp}])
      ~title:"Competition" ~perms:[View_comp {ev;comp}]
  in
  [
    admin_panel ~req ~st ~ev ~comp;
    div [class_ "row"] [
      div
        [ path_attr Hx.get Paths.Htmx.comp_view (Ftw.Competition.id comp);
          Hx.swap "innerHTML"; Hx.trigger "intersect";]
        [
          div [class_ "spinnner spinner-border"; role `status] [
            span [class_ "visually-hidden"] [txt "Loading..."]
          ]
        ]
    ]
  ]


(* Main htmx view *)
(* ************************************************************************* *)

let target_row ~st ?rank ~target () =
  match (target : _ Ftw.Target.any) with
  | Any Couple { leader; follower; } ->
    let leader = Ftw.Dancer.get ~st leader in
    let follower = Ftw.Dancer.get ~st follower in
    tr [] [
      td [] (match rank with
            | Some r -> [txt "%d" (Ftw.Rank.rank r)]
            | None -> []);
      td [] [txt "%s %s" (Ftw.Dancer.first_name leader) (Ftw.Dancer.last_name leader)];
      td [] [txt "%s %s" (Ftw.Dancer.first_name follower) (Ftw.Dancer.last_name follower)];
    ]
  | Any Single { target; role; } ->
    let dancer = Ftw.Dancer.get ~st target in
    tr [] [
      td [] (match rank with
            | Some r -> [txt "%d" (Ftw.Rank.rank r)]
            | None -> []);
      td [] (match role with
            | Leader -> [txt "%s %s" (Ftw.Dancer.first_name dancer) (Ftw.Dancer.last_name dancer)]
            | Follower -> []);
      td [] (match role with
            | Follower -> [txt "%s %s" (Ftw.Dancer.first_name dancer) (Ftw.Dancer.last_name dancer)]
            | Leader -> []);
    ]
  | _ -> assert false

let table_of_ranking ~st (ranking : Ftw.Results.ranking) =
  table [class_ "table table-striped"] [
    thead [] [
      tr [][
        th [] [txt "Rank"];
        th [] [txt "Leader"];
        th [] [txt "Follower"];
      ]
    ];
    tbody [] (
      Array.to_list @@ CCArray.flat_map (fun ranked ->
      match (ranked : _ Ftw.Ranking.One.ranked) with
      | None -> [| |]
      | Ranked { rank; target; } ->
        [| target_row ~st ~rank ~target () |]
      | Tie { rank; tie; } ->
        Array.mapi (fun i target ->
          let rank = if i = 0 then Some rank else None in
          target_row ?rank ~st ~target ()
        ) tie
      ) ranking.final_ranks.ranks)
  ]

let htmx_view req comp_id =
  let$ st = State.get req in
  let comp = Ftw.Competition.get ~st comp_id in
  let ev = Ftw.Event.get ~st (Ftw.Competition.event comp) in
  match Ftw.Competition.status comp with
  | Setup ->
    let$ () = Htmx.ret' ~req ~st ~perms:[View_comp {ev;comp;}] in
    `Body [txt "Setup in progress..."]
  | Registration ->
    let$ () = Htmx.ret' ~req ~st ~perms:[View_comp {ev;comp;}] in
    `Body [txt "Registration in progress..."]
  | Distribution ->
    let$ () = Htmx.ret' ~req ~st ~perms:[View_comp {ev;comp;}] in
    let n_leaders, n_followers = count_bibs ~st ~comp in
    `Body [
        div [class_ "row"] [
          div [class_ "col"] [
            txt "Leaders : %d" n_leaders;
          ];
          div [class_ "col"] [
            txt "Followers : %d" n_followers;
          ];
        ];
      ]
  | Progress ->
    let$ () = Htmx.ret' ~req ~st ~perms:[View_comp {ev;comp;}] in
    let phases = Ftw.Competition.phases ~st comp in
    let phase_opt =
      List.find_opt (fun phase ->
        Ftw_core.Phase.status phase <> Ftw_core.Phase.Finished
      ) phases
    in
    begin match phase_opt with
    | Some phase ->
      `Body [
        div
          [ path_attr Hx.get Paths.Htmx.phase_view (Ftw.Phase.id phase);
            Hx.swap "innerHTML"; Hx.trigger "revealed once";]
          [
            div [class_ "spinnner spinner-border"; role `status] [
              span [class_ "visually-hidden"] [txt "Loading..."]
            ]
          ]
        ]
    | None ->
      (* TODO: print the presumptive results and promotions *)
      `Body [txt "Competition almost finished..."]
    end 
  | Finished ->
    let$ () = Htmx.ret' ~req ~st ~perms:[View_comp {ev;comp;}] in
    let results = Ftw.Results.find ~st (`Competition comp) in
    let ranking = Ftw.Results.ranking ~comp results in
    let finals_table = table_of_ranking ~st ranking in
    `Body [finals_table]
