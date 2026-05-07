
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Competition result *)
(* ************************************************************************* *)

type aux =
  | Not_present      (* or unknown *)
  | Present          (* but rank unknown *)
  | Ranked of Rank.t (* actual ranks, the list should be non-empty *)

type t = {
  prelims :       aux;
  octofinals :    aux;
  quarterfinals : aux;
  semifinals :    aux;
  finals :        aux;
}

type o = {
  dancer : Dancer.id;
  role : Role.t;
  points : Points.t;
  result : t;
}

type p = {
  dancer : Dancer.id;
  points : Points.t;
}

type r = {
  competition : Competition.id;
  target : p Target.any;
  result : t;
}


let mk
    ?(prelims=Not_present)
    ?(octofinals=Not_present)
    ?(quarterfinals=Not_present)
    ?(semifinals=Not_present)
    ?(finals=Not_present) () =
  { prelims; octofinals; quarterfinals; semifinals; finals; }

(* Some values *)

let finalist = mk () ~finals:Present
let semifinalist = mk () ~semifinals:Present
let quarterfinalist = mk () ~quarterfinals:Present
let octofinalist = mk () ~octofinals:Present

let placement (t : t) : Points.placement =
  match t.finals with
  | Present -> Finals None
  | Ranked rank -> Finals (Some rank)
  | Not_present ->
    begin match t.semifinals with
      | Present | Ranked _ -> Semifinals
      | Not_present -> Other
    end

(* Points *)
(* ************************************************************************* *)

let explode r =
  Target.to_list r.target
  |> List.map (fun ({ dancer; points }, role) ->
    { dancer; role; points; result = r.result; }
  )

let points ~event ~comp ~role result =
  match Competition.category comp with
  | Non_competitive _ -> 0
  | Competitive _ ->
    let date = Event.start_date event in
    let n =
      match (role : Role.t) with
      | Leader -> Competition.n_leaders comp
      | Follower -> Competition.n_follows comp
    in
    let placement = placement result in
    Points.find ~date ~n ~placement


(* Ordering results *)
(* ************************************************************************* *)

type 'kind ranking = {
  finalists : ('kind, Dancer.id) Target.t Ranking.One.t;
  semifinalists : Dancer.id list;
  quarterfinalists : Dancer.id list;
  octofinalists : Dancer.id list;
  only_prelims : Dancer.id list;
}

type any_ranking = Any : _ ranking -> any_ranking

let ranking ~comp:_ results =
  let max_final_rank_index = ref 0 in
  let finals = Array.make 100 [] in
  let semifinalist = ref [] in
  let quarterfinalists = ref [] in
  let octofinalists = ref [] in
  let prelims = ref [] in
  List.iter (fun (r : r) -> 
    match r.result.finals with
    | Ranked rank ->
      let i = Rank.to_index rank in
      max_final_rank_index := max i !max_final_rank_index;
      finals.(i) <- r :: finals.(i)
      | _ -> ()
    ) results;
  let ranks =
    Array.init (!max_final_rank_index + 1) (fun _i ->
      Ranking.One.None
      (*
      match Competition.kind comp, finals.(i) with
      | (Routine | Strictly | JJ_Strictly | Jack_and_Jill), [r1; r2] ->
        let leader, follower =
          match r1.role, r2.role with
          | Leader, Follower -> r1.dancer, r2.dancer
          | Follower, Leader -> r2.dancer, r1.dancer
          | _ -> assert false (* TODO: proper error *)
        in
        let couple : (Target.couple, Dancer.id) Target.t =
          Couple { leader; follower; }
        in
        Ranking.One.
      | _ ->
        assert false
        *)
      )
  in
  Any {
    finalists = Ranking.One.{ ranks; };
    semifinalists = !semifinalist;
    quarterfinalists = !quarterfinalists;
    octofinalists = !octofinalists;
    only_prelims = !prelims;
  }
  

