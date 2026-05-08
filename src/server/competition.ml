
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Dream_html
open Dream_html.HTML

(* API for results *)
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

let api_results req comp_id =
  State.get req @@ fun st ->
  let _user = User.get req in
  let comp = Ftw.Competition.get ~st comp_id in
  let results = Ftw.Results.find ~st (`Competition comp) in
  let ranking = Ftw.Results.ranking ~comp results in
  let finals_table = table_of_ranking ~st ranking in
  Template.api ~body:[finals_table]