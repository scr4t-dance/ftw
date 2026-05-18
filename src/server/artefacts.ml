
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Syntax
open! Dream_html
open! Dream_html.HTML

module M = Ftw.Ranking.Matrix

(* Overall view *)
(* ************************************************************************* *)

let yan_weighted_infos ~req ~st ~comp ~judge_criterions ~head_criterions ~matrix =
  let judges =
    List.init (M.width matrix) (fun j ->
      let head = M.is_head matrix ~j in
      let judge_id = M.judge matrix ~j in
      let dancer = Ftw.Dancer.get ~st judge_id in
      dancer, head
    )
  in
  table [class_ "table table-hover"] [
    thead [] [
      tr [] ([ 
        th [] [];
        th [] [];
        th [] [];
        th [] [];
        ] @ (List.map (fun (dancer, head) ->
        th [colspan 3] [txt "%s%s" (Ftw.Dancer.first_name dancer) (if head then "*" else "")]
        ) judges)
      );
      tr [] ([ 
        th [scope "col"] [txt "Rank"];
        th [scope "col"] [txt "#"];
        th [scope "col"] [txt "Dancer"];
        th [scope "col"] [txt "Score"];
        ] @ (List.flatten @@
              List.map (fun (_dancer, head) ->
                List.map (fun criterion ->
                  th [scope "col"] [txt "%s" criterion]
                ) (if head then head_criterions else judge_criterions)
              ) judges)
      )];
    tbody [] (List.init (M.length matrix) (fun i ->
      let target = Ftw.Heat.get_one ~st (M.target  matrix ~i) in
      let target = Ftw.Target.map_any ~f:(Ftw.Dancer.get ~st) target in
      let ranked = (M.ranks matrix).ranks.(i) in
      (tr [] (
        (* Rank *)
        td [] [match ranked with
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
        (List.init (M.width matrix) (fun j ->
          null []
        ))
      ))))
  ]

let with_info ~req ~st ~comp ~ranking =
  match Ftw.Ranking.Res.info ranking with
  | RPSS _ -> assert false
  | Yan_weighted matrix -> yan_weighted_infos ~req ~st ~comp ~matrix

