
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw.results"

(* Competition result *)
(* ************************************************************************* *)

type aux =
  | Not_present           (* or unknown *)
  | Present               (* but rank unknown *)
  | Ranked of Rank.t list (* actual ranks, the list should be non-empty *)

type t = {
  prelims :       aux;
  octofinals :    aux;
  quarterfinals : aux;
  semifinals :    aux;
  finals :        aux;
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
  | Ranked [] -> assert false (* internal assumption *)
  | Ranked (rank :: other_ranks) ->
    let r = List.fold_left Rank.min rank other_ranks in
    Finals (Some r)
  | Not_present ->
    begin match t.semifinals with
      | Present | Ranked _ -> Semifinals
      | Not_present -> Other
    end

(* Int conversion *)
(* ************************************************************************* *)

let aux_to_int t =
  let rec aux = function
    | [] -> 0
    | rank :: l ->
      let i = Rank.rank rank in
      assert (1 <= i && i <= 254);
      let j = aux l in
      (* check that we do not overflow the integer *)
      assert (j land 0x7fff000000000000 = 0);
      i + (j lsl 8)
  in
  match t with
  | Not_present -> 0
  | Present -> 255
  | Ranked l -> aux l

let aux_of_int i =
  let rec aux i =
    if i = 0 then []
    else begin
      let r = Rank.mk (i land 0xff) in
      let i' = i lsr 8 in
      r :: aux i'
    end
  in
  match i with
  | 0 -> Not_present
  | 255 -> Present
  | _ -> Ranked (aux i)


(* TOML serialization *)
(* ************************************************************************* *)

let to_toml t =
  (* duplicate a bit the functions from `Rank`, but we really want to ensure
     that we can safely use `0` and that won't be confused with a rank *)
  let rank_to_toml r = Otoml.integer (Rank.rank r) in
  let aux name t' acc =
    match t' with
    | Not_present -> acc
    | Present -> (name, Otoml.integer 0) :: acc
    | Ranked [r] -> (name, rank_to_toml r) :: acc
    | Ranked l -> (name, Otoml.array (List.map rank_to_toml l)) :: acc
  in
  []
  |> aux "prelims" t.prelims
  |> aux "octofinals" t.octofinals
  |> aux "quarterfinals" t.quarterfinals
  |> aux "semifinals" t.semifinals
  |> aux "finals" t.finals
  |> Otoml.inline_table

let of_toml t =
  let aux_of_toml t =
    match Otoml.get_opt Otoml.get_integer t with
    | Some 0 -> Present
    | Some i -> Ranked [Rank.mk i]
    | None ->
      match Otoml.get_opt (Otoml.get_array Otoml.get_integer) t with
      | Some l -> Ranked (List.map Rank.mk l)
      | None -> raise (Otoml.Type_error "not the result of a phase")
  in
  let aux t name =
    match Otoml.find_opt t aux_of_toml [name] with
    | None -> Not_present
    | Some ret -> ret
  in
  {
    prelims = aux t "prelims";
    octofinals = aux t "octofinals";
    quarterfinals = aux t "quarterfinals";
    semifinals = aux t "semifinals";
    finals = aux t "finals";
  }

(* Misc *)
(* ************************************************************************* *)

let merge_aux r r' =
  match r, r' with
  | Not_present, r''
  | r'', Not_present
  | Present, (Present as r'')
  | Present, ((Ranked _) as r'')
  | ((Ranked _) as r''), Present -> r''
  | Ranked l, Ranked l' -> Ranked (l @ l')

let merge r r' = {
  prelims = merge_aux r.prelims r'.prelims;
  octofinals = merge_aux r.octofinals r'.octofinals;
  quarterfinals = merge_aux r.quarterfinals r'.quarterfinals;
  semifinals = merge_aux r.semifinals r'.semifinals;
  finals = merge_aux r.finals r'.finals;
  }


(* DB interaction *)
(* ************************************************************************* *)

let () =
  State.add_init ~name:"results" (fun st ->
      State.exec ~st {|
        CREATE TABLE IF NOT EXISTS results (
          competition INTEGER REFERENCES competitions(id),
          dancer INTEGER REFERENCES dancers(id),
          role INTEGER,
          points INTEGER,
          prelims INTEGER,
          octofinals INTEGER,
          quarterfinals INTEGER,
          semifinals INTEGER,
          finals INTEGER,
          PRIMARY KEY (competition, dancer, role)
        )
      |})

type r = {
  competition : Competition.id;
  dancer : Dancer.id;
  role : Role.t;
  points : Points.t;
  result : t;
}

let conv =
  Conv.mk Sqlite3_utils.Ty.[int; int; int; int; int; int; int; int; int]
    (fun competition dancer role points prelims octo quarter semi finals ->
       let role = Role.of_int role in
       let result = {
         prelims = aux_of_int prelims;
         octofinals = aux_of_int octo;
         quarterfinals = aux_of_int quarter;
         semifinals = aux_of_int semi;
         finals = aux_of_int finals;
       }
       in
       { competition; dancer; role; result; points; })

let add ~st ~competition ~dancer ~role ~result ~points =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int; int; int; int; int; int; int; int; int]
    {| INSERT INTO results
        (competition,dancer,role,points,prelims,octofinals,quarterfinals,semifinals,finals)
        VALUES (?,?,?,?,?,?,?,?,?) |}
    competition dancer (Role.to_int role) points
    (aux_to_int result.prelims)
    (aux_to_int result.octofinals)
    (aux_to_int result.quarterfinals)
    (aux_to_int result.semifinals)
    (aux_to_int result.finals)

let find ~st = function
  | `Competition competition ->
    State.query_list_where ~st ~p:Id.p ~conv
      {| SELECT * FROM results WHERE competition = ? |} competition
  | `Dancer dancer ->
    State.query_list_where ~st ~p:Id.p ~conv
      {| SELECT * FROM results WHERE dancer = ? |} dancer

let all_points ~st ~dancer ~role ~div =
  let open Sqlite3_utils.Ty in
  let conv = Conv.mk [nullable int] CCFun.id in
  CCOption.get_or ~default:0 @@
  State.query_one_where ~st ~conv ~p:[int; int; int]
    {| SELECT SUM(results.points)
       FROM results JOIN competitions ON results.competition=competitions.id
       WHERE results.dancer = ? AND results.role = ? AND competitions.category = ? |}
    dancer
    (Role.to_int role)
    (Category.to_int (Competitive div))

let all_points_before ~st ~dancer ~role ~div ~end_date =
  let open Sqlite3_utils.Ty in
  let conv = Conv.mk [nullable int] CCFun.id in
  CCOption.get_or ~default:0 @@
  State.query_one_where ~st ~conv ~p:[int; int; int;text]
    {| SELECT SUM(results.points)
       FROM results
       JOIN competitions
       ON results.competition=competitions.id
       JOIN events
       ON competitions.event = events.id
       WHERE results.dancer = ?
       AND results.role = ?
       AND competitions.category = ?
       AND events.end_date < ? |}
    dancer
    (Role.to_int role)
    (Category.to_int (Competitive div))
    (Date.to_string end_date)


(* TODO: rewrite all uses of this function, this recomputes the while ranking for each dancer,
   that's not very efficient *)
let update_finals ~st ~(dancer:Dancer.id) ~(role:Role.t) p_list =
  begin match List.find_opt (fun p -> (Round.compare (Phase.round p) Round.Finals)== 0) p_list with
    | Some p ->
      let ranking = Heat.ranking ~st ~phase:(Phase.id p) in
      let r = begin match ranking with
        | Singles {leaders; follows} ->
          let r = begin match role with
            | Leader -> Ranking.Res.ranking leaders
            | Follower -> Ranking.Res.ranking follows
          end in r
        | Couples {couples} -> Ranking.Res.ranking couples
      end in
      let n = Array.length r.ranks in
      let rank_option_list = List.init n (fun i ->
          let opt = Ranking.One.get r (Rank.of_index i) in
          let target_opt = Option.map (fun (rank, tid) -> rank, Heat.get_one ~st tid) opt in
          begin match target_opt with
            | Some (rank, Target.Any Target.Single ({target;_})) when target == dancer -> Some rank
            | Some (rank, Target.Any Target.Couple ({leader;_})) when leader == dancer -> Some rank
            | Some (rank, Target.Any Target.Couple ({follower;_})) when follower == dancer -> Some rank
            | _ -> None
          end
        ) in
      let rank_option = List.find_opt Option.is_some rank_option_list |> Option.join in
      begin match rank_option with
        | Some rank -> Ranked [rank]
        | None -> raise Not_found
      end
    | None -> Not_present
  end

let points ~st ~event ~comp ~role result =
  match Competition.category comp with
  | Non_competitive _ -> 0
  | Competitive _ ->
    let date = Event.start_date (Event.get st event) in
    let n =
      match (role : Role.t) with
      | Leader -> Competition.n_leaders comp
      | Follower -> Competition.n_follows comp
    in
    let placement = placement result in
    Points.find ~date ~n ~placement


let compute ~st ~competition =
  let phase_list = Phase.find st competition in
  let convert_couple_to_pair_of_dancers (Target.Couple { leader; follower; }) =
    (leader, follower) in
  let keep_role role =
    List.filter_map (fun t ->
        begin match t with
          | Target.Single {target;role=r;} when Role.equal role r -> Some target
          | _ -> None
        end) in
  let get_dancer_set (h:Heat.t) =
    let leader_list, follower_list =
      begin match h with
        | Singles sh ->
          let single_target_map, _, _ = Heat.all_single_judgement_targets sh in
          let target_list = Id.Map.bindings single_target_map |> List.map snd in
          let leader_list = keep_role Role.Leader target_list in
          let follower_list = keep_role Role.Follower target_list in
          leader_list, follower_list
        | Couples ch ->
          let couple_targets_map = Heat.all_couple_judgement_targets ch in
          let couple_target_list = Id.Map.bindings couple_targets_map |> List.map snd in
          let leader_list, follower_list = List.map
              convert_couple_to_pair_of_dancers couple_target_list |> List.split in
          leader_list, follower_list
      end in
    let leader_set = Id.Set.of_list leader_list in
    let follower_set = Id.Set.of_list follower_list in
    leader_set, follower_set in
  let leader_set_list, follower_set_list = List.map (
      fun p ->
        let heat = Heat.get ~st ~phase:(Phase.id p) in
        let fl_set = get_dancer_set heat in
        Logs.debug ~src (fun k -> k "%d leader %s ; follower %s"
        (Phase.id p)
        (fst fl_set |> Id.Set.elements |> List.map string_of_int |> String.concat ",")
        (snd fl_set |> Id.Set.elements |> List.map string_of_int |> String.concat ",")
        );
        fl_set
    ) phase_list |> List.split in
  let transpose_dancer_phase dancer_set_list p_list = List.fold_left2 (fun acc s p ->
      let add_to_list key m =
        let new_list = begin match Id.Map.find_opt key m with
          | None -> [p]
          | Some l -> p :: l
        end in
        Id.Map.add key new_list m in
      Id.Set.fold add_to_list s acc
    ) Id.Map.empty dancer_set_list p_list in
  let leader_map = transpose_dancer_phase leader_set_list phase_list in
  let follower_map = transpose_dancer_phase follower_set_list phase_list in
  let make_aux r p_list =
    begin match List.exists (fun p -> Round.equal (Phase.round p) r) p_list with
      | true -> Present
      | false -> Not_present
    end in
  let make_result p_list  =
    { prelims=make_aux Round.Prelims p_list;
      octofinals=make_aux Round.Octofinals p_list;
      quarterfinals=make_aux Round.Quarterfinals p_list;
      semifinals=make_aux Round.Semifinals p_list;
      finals=make_aux Round.Finals p_list; }
  in
  let make_t ~st ~role dancer_map =
    let updated_t = Id.Map.filter_map (fun dancer p_list ->
        let r = make_result p_list in
        Some { r with finals=update_finals ~st ~dancer ~role p_list}
      ) dancer_map |> Id.Map.bindings in
    List.iter (fun (dancer, result) ->
        let comp = Competition.get st competition in
        let points = points ~st ~event:(Competition.event comp) ~comp ~role result in
        add ~st ~competition ~dancer ~role ~result ~points
      ) updated_t
  in
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int;]
    {| DELETE FROM results
    WHERE competition = ? |}
    competition;
  let leader_set = List.fold_left Id.Set.union Id.Set.empty leader_set_list in
  let follower_set = List.fold_left Id.Set.union Id.Set.empty follower_set_list in
  Competition.update_competitors_number ~st ~id:competition ~n_leaders:(Id.Set.cardinal leader_set) ~n_followers:(Id.Set.cardinal follower_set);
  make_t ~st ~role:Role.Leader leader_map;
  make_t ~st ~role:Role.Follower follower_map;
  ()
