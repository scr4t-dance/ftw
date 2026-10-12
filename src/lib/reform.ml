
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Reform

(* Special promotion passes *)
(* ************************************************************************* *)

(* TODO: implement a DSL to make these user-defined and configurable *)

let apply1 ~st () =
  let apply_aux dancer role =
    let id = Dancer.id dancer in
    let divs = Dancer.as_role ~role dancer in
    match divs with
    | Intermediate ->
      let novice_points = Results.all_points ~st ~dancer:id ~role ~div:Novice in
      let inter_points = Results.all_points ~st ~dancer:id ~role ~div:Intermediate in
      if inter_points <= 0 && 12 <= novice_points && novice_points <= 14 then begin
        let new_divs : Divisions.t = Novice_Intermediate in
        let p : Promotion.t = {
          source = Reform First;
          dancer = id; role;
          old_divisions = divs;
          new_divisions = new_divs;
          reason = Reform;
        } in
        Promotion.record ~st p
      end
    | _ -> ()
  in
  Dancer.iter ~st ~f:(fun d ->
      apply_aux d Leader;
      apply_aux d Follower;
      ()
    )

let apply ~st t =
  match t with
  | First -> apply1 ~st ()

