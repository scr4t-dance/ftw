
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Syntax
open! Dream_html
open! Dream_html.HTML

module M = Ftw.Ranking.Matrix


(* Helpers *)
(* ************************************************************************* *)

let flmap f l =
  let rec aux acc status = function
  | [] -> List.rev acc
  | [x] ->
    begin match status with
      | `Start -> aux (List.rev_append (f `Only x) acc) `End []
      | _ -> aux (List.rev_append (f `End x) acc) `End []
    end
  | x :: r -> aux (List.rev_append (f status x) acc) `Middle r
in
aux [] `Start l

let flmap2 f l l' =
  let rec aux acc status l l' =
  match l, l' with
  | [], [] -> List.rev acc
  | [x], [y] ->
    begin match status with
     | `Start -> aux (List.rev_append (f `Only x y) acc) `End [] []
     | _ -> aux (List.rev_append (f `End x y) acc) `End [] []
  end
  | x :: r, y :: r' -> aux (List.rev_append (f status x y) acc) `Middle r r'
  | _ -> assert false
in
aux [] `Start l l'


(* Overall view *)
(* ************************************************************************* *)

let yan_weighted_headers ~phase ~judges ~judge_criterions ~head_criterions =
  thead [] [
      tr [] ([ 
        th [] [];
        th [] [];
        th [] [];
        th [] [];
        ] @ (List.map (fun (dancer, head) ->
        th
          [colspan (if head then 1 else 3); class_ "text-center border-start border-end border-dark"]
          [a
            [class_ "btn btn-secondary"; path_attr href Paths.Page.judge_artefacts (Ftw.Phase.id phase) (Ftw.Dancer.id dancer)]
            [txt "%s%s" (Ftw.Dancer.first_name dancer) (if head then "*" else "")]
          ]
        ) judges)
      );
      tr [] ([ 
        th [scope "col"] [txt "Rank"];
        th [scope "col"] [txt "#"];
        th [scope "col"] [txt "Dancer"];
        th [scope "col"] [txt "Score"];
        ] @ (flmap (fun _ (_dancer, head) ->
                flmap (fun pos criterion ->
                  let borders =
                    match pos with 
                    | `Start -> "border-start"
                    | `Middle -> ""
                    | `End -> "border-end"
                    | `Only -> "border-start border-end"
                  in
                  [th [scope "col"; class_ "border-dark %s" borders] [txt "%s" criterion]]
                ) (if head then head_criterions else judge_criterions)
              ) judges)
      )]

let yan_weighted_row ~req:_ ~st ~comp ~matrix ~i ~judge_criterions ~judge_weights ~head_criterions ~head_weights =
  let target = Ftw.Heat.get_one ~st (M.target  matrix ~i) in
  let target = Ftw.Target.map_any ~f:(Ftw.Dancer.get ~st) target in
  let ranked = (M.ranks matrix).ranks.(i) in
  tr [] (
    (* Rank *)
    td [] [match (ranked : _ Ftw.Ranking.One.ranked) with
      | None -> txt ""
      | Ranked { rank; target = _; } -> txt "%s" (Display.rank rank)
      | Tie { rank; tie = _; } ->
        if (Ftw.Rank.equal rank (Ftw.Rank.of_index i)) then
          txt "%s" (Display.rank rank)
        else
          txt ""
    ] ::
    (* Bib *)
    td [] [
      match Ftw.Bib.find ~st ~comp target with
      | None -> txt "?"
      | Some (bib, _) -> txt "#%d" bib
    ] ::
    (* Dancer/target *)
    td [] [txt "%s" (Display.target target)] ::
    (* Total score *)
    td [] [
      let Ftw.Ranking.Yan_weighted.{ judges; head; bonus } = M.get ~i matrix in
      if bonus = 0 then
        txt "%d / %d" judges head
      else
        txt "%d / %d.%d" judges head bonus
    ] ::
    (* Individual judges notes *)
    (List.flatten @@ List.init (M.width matrix) (fun j ->
      let head = M.is_head matrix ~j in
      let weights = if head then head_weights else judge_weights in
      match M.artefact matrix ~i ~j with
      | Some Yans l ->
        flmap2 (fun pos yan weights ->
          let borders =
            match pos with 
            | `Start -> "border-start"
            | `Middle -> ""
            | `End -> "border-end"
            | `Only -> "border-start border-end"
          in
          let color =
            match (yan : Ftw.Artefact.yan) with
            | Yes -> "table-success"
            | Alt -> "table-warning"
            | No -> "table-danger"
          in
          let score =
            match (yan : Ftw.Artefact.yan) with
            | Yes -> weights.Ftw.Ranking.Yan_weighted.yes
            | Alt -> weights.Ftw.Ranking.Yan_weighted.alt
            | No -> weights.Ftw.Ranking.Yan_weighted.no
          in
          [
            td [class_ "text-center border-dark %s %s" color borders]
              [txt "%d" score]
          ]
          ) l weights
      | _ ->
        let head = M.is_head matrix ~j in
        let criterions = if head then head_criterions else judge_criterions in
        List.map (fun _ ->
          td [class_ "table-dark"] []
          ) criterions
    ))
  )

let yan_weighted_infos ~req ~st ~comp ~phase ~matrix
  ~judge_criterions ~judge_weights ~head_criterions ~head_weights =
  let judges =
    List.init (M.width matrix) (fun j ->
      let head = M.is_head matrix ~j in
      let judge_id = M.judge matrix ~j in
      let dancer = Ftw.Dancer.get ~st judge_id in
      dancer, head
    )
  in
  table [class_ "table table-hover"] [
    yan_weighted_headers ~phase ~judges ~judge_criterions ~head_criterions;
    tbody [] (List.init (M.length matrix) (fun i ->
      yan_weighted_row ~req ~st ~comp ~matrix ~i ~judge_criterions ~judge_weights ~head_criterions ~head_weights
      ))
  ]

let rpss_headers ~judges ~phase ~n =
  thead [] [
    tr [] [
      th [] [];
      th [colspan 2; class_ "text-center border-end"] [txt "Couple"];
      th [colspan (List.length judges)] [txt "Judges Rankings"];
      th [colspan n] [txt "Relative Placements"]; 
    ];
    tr [] (
      th [] [txt "Rank"] ::
      th [] [txt "Leader"] ::
      th [] [txt "Follower"] ::
      (List.map (fun (judge, head) ->
        td [] [a
          [class_ "btn btn-secondary"; path_attr href Paths.Page.judge_artefacts (Ftw.Phase.id phase) (Ftw.Dancer.id judge)]
          [txt "%s%s" (Ftw.Dancer.first_name judge) (if head then "*" else "")]]
        ) judges)
      @ (List.init n (fun i ->
        th [] [txt "1-%d" (i + 1)]
        ))
    )
  ]

let rpss_row ~req:_ ~st ~comp ~phase:_ ~matrix ~i =
  let target = Ftw.Heat.get_one ~st (M.target matrix ~i) in
  let leader, follower =
    match Ftw.Target.map_any ~f:(Ftw.Dancer.get ~st) target with
    | Any Couple { leader; follower; } -> leader, follower
    | _ -> assert false
  in
  let ranked = (M.ranks matrix).ranks.(i) in
  let cells : Ftw.Ranking.RPSS.acc = M.get matrix ~i in
  tr [] (
    (* Rank *)
    td [] [match (ranked : _ Ftw.Ranking.One.ranked) with
      | None -> txt ""
      | Ranked { rank; target = _; } -> txt "%s" (Display.rank rank)
      | Tie { rank; tie = _; } ->
        if (Ftw.Rank.equal rank (Ftw.Rank.of_index i)) then
          txt "%s" (Display.rank rank)
        else
          txt ""
    ] ::
    (* Leader *)
    td [] [
      let target = Ftw.Target.(Any (Single { target = leader; role = Leader; })) in
      match Ftw.Bib.find ~st ~comp target with
      | None -> txt "???"
      | Some (bib, _) -> txt "#%d %s %s" bib (Ftw.Dancer.first_name leader) (Ftw.Dancer.last_name leader)
    ] ::
    (* Follower *)
    td [] [
      let target = Ftw.Target.(Any (Single { target = follower; role = Follower; })) in
      match Ftw.Bib.find ~st ~comp target with
      | None -> txt "???"
      | Some (bib, _) -> txt "#%d %s %s" bib (Ftw.Dancer.first_name follower) (Ftw.Dancer.last_name follower)
    ] ::
    (List.init (M.width matrix) (fun j ->
      match M.artefact matrix ~i ~j with
      | Some Rank r -> td [] [txt "%d" (Ftw.Rank.rank r)]
      | _ -> td [class_ "table-dark"] []
    )) @
    (List.init (M.length matrix) (fun k ->
      let cell = cells.(k) in
      match cell.votes, cell.sum, cell.head with
      | None, _, _ -> td [] [txt "--"]
      | Some 0, _, _ -> td [] []
      | Some v, None, None -> td [] [txt "%d" v]
      | Some v, Some s, None -> td [] [txt "%d (%d)" v s]
      | Some v, Some s, Some _ -> td [] [txt "%d (%d)*" v s]
      | _ -> td [class_ "table-danger"] [txt "??"]
      ))
  )

let rpss_info ~req ~st ~comp ~phase ~matrix =
  let n = M.length matrix in
  let judges =
    List.init (M.width matrix) (fun j ->
      let head = M.is_head matrix ~j in
      let judge_id = M.judge matrix ~j in
      let dancer = Ftw.Dancer.get ~st judge_id in
      dancer, head
    )
  in
  table [class_ "table"] [
    rpss_headers ~judges ~phase ~n;
    tbody [] (List.init (M.length matrix) (fun i ->
      rpss_row ~req ~st ~comp ~phase ~matrix ~i
      ));
  ]

let with_info ~req ~st ~comp ~phase ~ranking =
  match Ftw.Ranking.Res.info ranking with
  | RPSS matrix ->
    rpss_info ~req ~st ~comp ~phase ~matrix
  | Yan_weighted matrix ->
    let judge_criterions =
      match Ftw.Phase.judge_artefact_descr phase with
      | Yans { criterions } -> criterions
      | _ -> assert false
    in
    let head_criterions =
      match Ftw.Phase.head_judge_artefact_descr phase with
      | Yans { criterions } -> criterions
      | _ -> assert false
    in
    let judge_weights, head_weights =
      match Ftw.Phase.ranking_algorithm phase with
      | Yan_weighted { weights; head_weights; } -> weights, head_weights
      | _ -> assert false
  in
  yan_weighted_infos ~req ~st ~comp ~phase ~matrix ~judge_criterions ~judge_weights ~head_criterions ~head_weights

let ranking_view ~req ~st ~comp ~phase =
  let ranking = Ftw.Phase.ranking ~st ~phase in
  let l =
    match ranking with
    | Any Singles { leaders; follows; } ->
      [with_info ~req ~st ~comp ~phase ~ranking:leaders;
       with_info ~req ~st ~comp ~phase ~ranking:follows; ]
    | Any Couples { couples } ->
      [with_info ~req ~st ~comp ~phase ~ranking:couples]
  in
  div [class_ "row"] l

let htmx_view req phase_id =
  let$ st = State.get req in
  let phase = Ftw.Phase.get ~st phase_id in
  let comp = Ftw.Competition.get ~st (Ftw.Phase.competition phase) in
  let ev = Ftw.Event.get ~st (Ftw.Competition.event comp) in
  let$ () = Htmx.ret' ~req ~st ~perms:[View_artefacts {ev;comp;phase}] in
  `Body [ranking_view ~req ~st ~comp ~phase]


(* Individual judge view *)
(* ************************************************************************* *)

type yan_count = {
  mutable yes : int;
  mutable alt : int;
  mutable no : int;
}

type counter =
  | Yans of (string * yan_count) list
  | Other

let counter ~judging ~phase =
  let artefact_descr =
    match (judging : Ftw.Judging.t) with
    | Head _ -> Ftw.Phase.head_judge_artefact_descr phase
    | _ -> Ftw.Phase.judge_artefact_descr phase
  in
  match (artefact_descr: Ftw.Artefact.Descr.t) with
  | Ranking -> Other
  | Yans { criterions } ->
    Yans (List.map (fun criterion -> criterion, { yes = 0; alt = 0; no = 0 }) criterions)

let col_headers ~st:_ ~judging ~phase =
  let artefact_descr =
    match (judging : Ftw.Judging.t) with
    | Head _ -> Ftw.Phase.head_judge_artefact_descr phase
    | _ -> Ftw.Phase.judge_artefact_descr phase
  in
  match artefact_descr with
  | Ranking -> [td [] [txt "ranking"]]
  | Yans { criterions } -> List.map (fun criterion -> td [] [txt "%s" criterion]) criterions

let input_rank ~target_id ~rank =
  input [
    class_ "form-control"; type_ "number"; min "1"; name "%d" target_id;
    (match rank with
    | None -> placeholder "rank"
    | Some r -> value "%d" (Ftw.Rank.rank r))
  ]

let input_yan_num ~counter ~style ~target_id ~criterion ~yan =
  begin match counter, yan with
    | Yans l, Some Ftw.Artefact.Yes ->
      let c = List.assoc criterion l in
      c.yes <- c.yes + 1
    | Yans l, Some Ftw.Artefact.Alt ->
      let c = List.assoc criterion l in
      c.alt <- c.alt + 1
    | Yans l, Some Ftw.Artefact.No ->
      let c = List.assoc criterion l in
      c.no <- c.no + 1
    | _ -> ()
  end;
  match style with
  | `Radio ->
    div [class_ "btn-group d-block"; role `group ] [
      input [ type_ "radio"; class_ "btn-check"; value "3";
              name "%d-%s" target_id criterion;
              id "%d-%s-yes" target_id criterion;
              (match yan with Some Ftw.Artefact.Yes -> checked | _ -> null_)];
      label
        [class_ "btn btn-outline-success"; for_ "%d-%s-yes" target_id criterion]
        [txt "Yes"];
      input [ type_ "radio"; class_ "btn-check"; value "2";
              name "%d-%s" target_id criterion;
              id "%d-%s-alt" target_id criterion;
              (match yan with Some Ftw.Artefact.Alt -> checked | _ -> null_)];
      label
        [class_ "btn btn-outline-warning"; for_ "%d-%s-alt" target_id criterion]
        [txt "Alt"];
      input [ type_ "radio"; class_ "btn-check"; value "1";
              name "%d-%s" target_id criterion;
              id "%d-%s-no" target_id criterion;
              (match yan with None | Some Ftw.Artefact.No -> checked | _ -> null_) ];
      label
        [class_ "btn btn-outline-danger"; for_ "%d-%s-no" target_id criterion]
        [txt "No"];
    ]
  | `Nums ->
    input [
      type_ "number"; class_ "form-control";
      min "1"; max "3"; step "1";
      name "%d-%s" target_id criterion;
      (match yan with
      | None -> null_
      | Some Ftw.Artefact.Yes -> value "3"
      | Some Ftw.Artefact.Alt -> value "2"
      | Some Ftw.Artefact.No -> value "1"
      )
    ]

let cols ~req ~counter ~phase ~judge ~judging ~st ~target_id =
  let descr =
    match (judging : Ftw.Judging.t) with
    | Head _ -> Ftw.Phase.head_judge_artefact_descr phase
    | _ -> Ftw.Phase.judge_artefact_descr phase
  in
  let artefact =
    try Some (Ftw.Artefact.get ~st ~descr ~judge:(Ftw.Dancer.id judge) ~target:target_id)
    with Not_found -> None
  in
  match descr with
  | Ranking ->
    let rank =
      match artefact with
      | Some Rank r -> Some r
      | _ -> None
    in
    [td [] [input_rank ~target_id ~rank]]
  | Yans { criterions } ->
    let l =
      match artefact with
      | Some Yans l -> List.map (fun yan -> Some yan) l
      | _ -> List.map (fun _ -> None) criterions
    in
    let style =
      match Dream.query req "style" with
      | Some "radio" -> `Radio
      | _ -> `Nums
    in
    List.map2 (fun criterion yan ->
      td
        []
        [ input_yan_num ~counter ~style ~target_id ~criterion ~yan ]
    ) criterions l

let heat_table_singles ~req:_ ~st ~bib_map ~role ~passages ~col_headers ~cols targets =
  let dancers =
    List.map (fun target_with_id ->
      let target_id = Ftw.Target.With_id.id target_with_id in
      let target = Ftw.Target.With_id.target target_with_id in
      let Ftw.Target.Single { target = dancer_id; role = _; } = target in
      let dancer = Ftw.Dancer.get ~st dancer_id in
      let bib_opt = Ftw.Bib.TMap.find_opt (Ftw.Target.Any target) bib_map in
      let passage : Ftw.Heat.passage_kind =
        try Ftw.Id.Map.find dancer_id passages
        with Not_found -> Only
      in
      target_id, bib_opt, passage, dancer
    ) targets
    |> List.sort (fun (_, b, _, _) (_, b', _, _) -> CCOrd.option Ftw.Id.compare b b')
  in
  div [class_ "col"] [
    h5 [] [txt "%s" (match (role : Ftw.Role.t) with Leader -> "Leader" | Follower -> "Follower")];
    table [class_ "table table-hover"] (
      thead [] [
        tr [] ([
          th [] [txt "#"];
          th [] [txt "Dancer"];
        ] @ col_headers);
      ] ::
      (List.map (fun (target_id, bib_opt, passage, dancer) ->
        match passage, bib_opt with
        | Ftw.Heat.Multiple { nth }, _ when nth > 1 -> null []
        | _,  Some bib ->
          tr [] ([
            td [] [txt "#%d" bib];
            td [] [txt "%s %s" (Ftw.Dancer.first_name dancer) (Ftw.Dancer.last_name dancer)];
          ] @ cols ~st ~target_id)
        | _, None ->
          tr [] [
            td
              [colspan (2 + List.length col_headers); class_ "text-danger"]
              [txt "Missing bib for %s %s" (Ftw.Dancer.first_name dancer) (Ftw.Dancer.last_name dancer)]
          ]
        ) dancers)
    );
  ]

let heat_table_couples ~req:_ ~st ~bib_map ~col_headers ~cols targets =
  let dancers =
    List.map (fun target_with_id ->
      let target_id = Ftw.Target.With_id.id target_with_id in
      let target = Ftw.Target.With_id.target target_with_id in
      let Ftw.Target.Couple { leader; follower } = target in

      let leader_bib_opt = Ftw.Bib.TMap.find_opt (Ftw.Target.Any (Single { target = leader; role = Leader; })) bib_map in
      let follower_bib_opt = Ftw.Bib.TMap.find_opt (Ftw.Target.Any (Single { target = follower; role = Follower; })) bib_map in
      
      let leader = Ftw.Dancer.get ~st leader in
      let follower = Ftw.Dancer.get ~st follower in
      target_id, leader_bib_opt, leader, follower_bib_opt, follower
    ) targets
    |> List.sort (fun (_, b, _, _, _) (_, b', _, _, _) -> CCOrd.option Ftw.Id.compare b b')
  in
  div [class_ "col"] [
    h5 [] [txt "Couples"];
    table [class_ "table table-hover"] (
      thead [] [
        tr [] ([
          th [] [txt "#"];
          th [] [txt "Leader"];
          th [] [txt "#"];
          th [] [txt "Follower"];
        ] @ col_headers);
      ] ::
      (List.map (fun (target_id, leader_bib_opt, leader, follow_bib_opt, follower) ->
        match leader_bib_opt, follow_bib_opt with
        | Some lbib, Some fbib ->
          tr [] ([
            td [] [txt "#%d" lbib];
            td [] [txt "%s %s" (Ftw.Dancer.first_name leader) (Ftw.Dancer.last_name leader)];
            td [] [txt "#%d" fbib];
            td [] [txt "%s %s" (Ftw.Dancer.first_name follower) (Ftw.Dancer.last_name follower)];
          ] @ cols ~st ~target_id)
        | _ ->
          tr [] [
            td
              [colspan (2 + List.length col_headers); class_ "text-danger"]
              [txt "Missing bib for %s %s & %s %s"
                    (Ftw.Dancer.first_name leader) (Ftw.Dancer.last_name leader)
                    (Ftw.Dancer.first_name follower) (Ftw.Dancer.last_name follower) ]
          ]
        ) dancers)
    );
  ]

let one_heat_view ~req ~st ~judging ~bib_map ~col_headers ~cols ~i (heat : Ftw.Heat.one) =
  match heat.leaders, heat.followers, heat.couples with
  | [], [], [] -> null []
  | _ ->
    div [class_ "row py-3 border-bottom"] (
        h4 [] [if i = 0 then txt "Unallocated" else txt "Heat %d" i] :: (
        (match (judging : Ftw.Judging.t) with
          | Leaders ->
            [heat_table_singles ~req ~st ~bib_map ~passages:heat.passages ~col_headers ~cols ~role:Leader heat.leaders]
          | Followers ->
            [heat_table_singles ~req ~st ~bib_map ~passages:heat.passages ~col_headers ~cols ~role:Follower heat.followers]
          | Head { targets = `Singles } ->
            [heat_table_singles ~req ~st ~bib_map ~passages:heat.passages ~col_headers ~cols ~role:Leader heat.leaders;
            heat_table_singles ~req ~st ~bib_map ~passages:heat.passages ~col_headers ~cols ~role:Follower heat.followers]
          | Couples | Head { targets = `Couples } ->
            [heat_table_couples ~req ~st ~bib_map ~col_headers ~cols heat.couples]
        )))

let regular_heat_view ~req ~st ~judging ~bib_map ~unallocated ~col_headers ~cols heats =
  List.mapi (fun i (heat : Ftw.Heat.one) ->
    one_heat_view ~req ~st ~judging ~bib_map ~col_headers ~cols ~i heat
  ) (unallocated :: heats)

let heat_view ~req ~st ~comp ~phase ~judge =
  let bib_map = Ftw.Bib.get_map ~st ~comp in
  let heat = Ftw.Heat.get ~st ~phase:(Ftw.Phase.id phase) in
  let panel = Ftw.Judge.get ~st ~phase:(Ftw.Phase.id phase) in
  match Ftw.Judge.judging panel judge with
  | None -> Other, null [] (* TODO: error *)
  | Some judging ->
    let counter = counter ~judging ~phase in
    let col_headers = col_headers ~st ~judging ~phase in
    let cols = cols ~req ~counter ~phase ~judging ~judge in
    match heat with
    | Regular { heats; unallocated; } ->
      let l = Array.to_list heats in
      counter,
      form [method_ `POST; path_attr action Paths.Post.artefacts (Ftw.Phase.id phase) (Ftw.Dancer.id judge)] (
        csrf_tag req ::
        regular_heat_view ~req ~st ~judging ~bib_map ~unallocated ~col_headers ~cols l @
        [button
          [type_ "submit"; class_ "btn btn-primary"]
          [txt "Save Artefacts"] ]
      )

let counter_view ~st:_ ~comp ~phase = function
  | Other -> null []
  | Yans l ->
    let _, n_yes = Ftw.Competition.next_round comp (Some (Ftw.Phase.round phase)) in
    div [class_ "row border rounded mx-2 my-2"] [
      h6 [] [txt "Summary"];
      div [class_ "row"] (List.map (fun (criterion, c) ->
        div [class_ "col"] [
          txt "%s :" criterion;
          table [class_ "table border"] [
            tr [class_ "table-success border"] [
              td [] [
                txt "Yes: %d / %d" c.yes n_yes;
                if c.yes <> n_yes then
                  i [class_ "px-2 text-danger bi bi-exclamation-triangle-fill"] []
                else null [];
              ];
            ];
            tr [class_ "table-warning border"] [
              td [] [txt "Alt: %d" c.alt];
            ];
            tr [class_ "table-danger border"] [
              td [] [txt "No: %d" c.no];
            ];
          ]
        ]
        ) l)
    ]

let for_one_judge req phase_id judge_id =
  let$ st = State.get req in
  let phase = Ftw.Phase.get ~st phase_id in
  let comp = Ftw.Competition.get ~st (Ftw.Phase.competition phase) in
  let ev = Ftw.Event.get ~st (Ftw.Competition.event comp) in
  let judge = Ftw.Dancer.get ~st judge_id in
  let$ () =
    Page.mk' ~req ~st ~title:"Artefacts"
      ~root:(Event [Event{ev};Comp{comp};Phase{phase};Artefacts])
      ~perms:[Edit_artefacts {ev;comp;phase;judge}]
  in
  let counter, heats_views = heat_view ~req ~st ~comp ~phase ~judge in [
    h4
      [class_ "text-center"]
      [txt "Artefacts - %s %s" (Ftw.Dancer.first_name judge) (Ftw.Dancer.last_name judge)];
    counter_view ~st ~comp ~phase counter;
    heats_views
  ]

(* Updating artefacts *)
(* ************************************************************************* *)

let form_decode_yan = function
  | "1" -> Some Ftw.Artefact.No
  | "2" -> Some Ftw.Artefact.Alt
  | "3" -> Some Ftw.Artefact.Yes
  | _ -> None

let split_form_name s =
  match String.split_on_char '-' s with
  | [target; name] -> int_of_string target, name
  | _ -> assert false

let rec parse_yans ~res ~criterions = function
  | [] -> res
  | ((s, _) :: _) as l ->
    let target, _ = split_form_name s in
    parse_yans_target ~res ~criterions ~target ~acc:[] l

and parse_yans_target ~res ~criterions ~target ~acc = function
    | [] -> parse_yan_record ~res ~criterions ~target ~acc []
    | ((s, v) :: r) as l ->
      let target', criterion = split_form_name s in
      if Ftw.Id.equal target target' then
        parse_yans_target
        ~res ~criterions ~target
        ~acc:((criterion, form_decode_yan v) :: acc) r
      else parse_yan_record ~res ~criterions ~target ~acc l

and parse_yan_record ~res ~criterions ~target ~acc l =
  let yan_opt_list = List.map (fun criterion -> List.assoc_opt criterion acc) criterions in
  let yan_list = Option.bind (CCOption.sequence_l yan_opt_list) CCOption.sequence_l in
  let res =
    match yan_list with
    | Some yan_list -> (target, Ftw.Artefact.Yans yan_list) :: res
    | None -> res
  in
  parse_yans ~res ~criterions l

let rec parse_ranks ~res = function
  | [] -> res
  | (target, rank) :: r ->
    let target_id = int_of_string target in
    let rank = Ftw.Artefact.Rank (Ftw.Rank.mk (int_of_string rank)) in
    let res = (target_id, rank) :: res in
    parse_ranks ~res r

let parse_form_results ~st ~phase ~judge form_results =
  let panel = Ftw.Judge.get ~st ~phase:(Ftw.Phase.id phase) in
  let judging = Ftw.Judge.judging panel judge in
  let heat = Ftw.Heat.get ~st ~phase:(Ftw.Phase.id phase) in
  let l = 
    match heat with 
    | Regular reg ->
      let dancers =
        match judging with
        | Some Leaders ->
          let _map, leaders, _followers = Ftw.Heat.all_single_judgement_targets reg in
          leaders
        | Some Followers ->
          let _map, _leaders, followers = Ftw.Heat.all_single_judgement_targets reg in
          followers
        | Some Head { targets = `Singles } ->
          let _map, leaders, followers = Ftw.Heat.all_single_judgement_targets reg in
          leaders @ followers
        | Some Couples | Some Head { targets = `Couples } ->
          let map = Ftw.Heat.all_couple_judgement_targets reg in
          List.map fst (Ftw.Id.Map.bindings map)
        | None -> assert false
      in
      let artefact_descr =
        match judging with
        | Some Head _ -> Ftw.Phase.head_judge_artefact_descr phase
        | _ -> Ftw.Phase.judge_artefact_descr phase
      in
      begin match artefact_descr with
        | Ranking ->
          let l = parse_ranks ~res:[] form_results in
          List.iter (fun (target, _) ->
            if List.mem target dancers then () else assert false
            ) l;
          l
        | Yans { criterions } ->
          let l = parse_yans ~res:[] ~criterions form_results in
          List.iter (fun (target, _) ->
            if List.mem target dancers then () else assert false
            ) l;
          l
      end
  in
  l

let post_artefacts req phase_id judge_id =
  let$ st = State.get req in
  let phase = Ftw.Phase.get ~st phase_id in
  let comp = Ftw.Competition.get ~st (Ftw.Phase.competition phase) in
  let ev = Ftw.Event.get ~st (Ftw.Competition.event comp) in
  let judge = Ftw.Dancer.get ~st judge_id in
  match%lwt Dream.form req with
  | `Ok form_results ->
    if User.check_perms ~req ~st [Edit_artefacts {ev;comp;phase;judge}] then
      let l = parse_form_results ~st ~phase ~judge form_results in
      Ftw.Artefact.clear ~st ~phase:phase_id ~judge:judge_id;
      List.iter (fun (target, artefact) -> Ftw.Artefact.set ~st ~judge:judge_id ~target artefact) l;
      Dream.redirect req Paths.(render @@ apply Page.judge_artefacts phase_id judge_id)
    else
      assert false
  | _ -> assert false