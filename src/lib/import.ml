
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Misc.Result
let src = Logs.Src.create "ftw.import"

(* Judges *)
(* ************************************************************************* *)

type judge =
  | Bonus
  | Head of Judge.id
  | Judge of Judge.id

let split_judge_list l =
  let judges, head =
    CCList.partition_filter_map (function
        | Bonus -> `Drop
        | Judge id -> `Left id
        | Head id -> `Right id
      ) l
  in
  match head with
  | [] -> judges, None
  | [id] -> judges, Some id
  | _ -> assert false

let make_singles_panel leader_judges follow_judges =
  let leaders, head = split_judge_list leader_judges in
  let followers, head' = split_judge_list follow_judges in
  assert (Option.equal Id.equal head head');
  Judge.Singles { leaders; followers; head; }

let make_couples_panel judges =
  let couples, head = split_judge_list judges in
  Judge.Couples { couples; head; }


(* Bibs, TSV & parsing helpers *)
(* ************************************************************************* *)

let extract_bib s =
  let s = String.trim s in
  if s = "" then None
  else begin
    let s =
      if String.starts_with ~prefix:"#" s
      then String.sub s 1 (String.length s - 1)
      else s
    in
    Some (int_of_string (String.trim s))
  end

let extract_bib' s =
  match String.split_on_char ' ' s with
  | bib :: _ ->
    begin match extract_bib bib with
      | Some bib -> bib
      | None -> assert false
    end
  | _ -> assert false

let split_tsv_line ?(comments=true) s =
  match String.trim s with
  | "" -> None
  | _ ->
    if comments && s.[0] = '#' then None
    else Some (String.split_on_char '\t' s)

let split_tsv ?comments s =
  let l = String.split_on_char '\n' s in
  List.filter_map (split_tsv_line ?comments) l

let yan_of_note = function
  | "1" -> Artefact.No
  | "2" -> Artefact.Alt
  | "3" -> Artefact.Yes
  | _ -> assert false

let bonus_of_note s =
  let f = float_of_string s in
  int_of_float (f *. 1.0)

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
    let placement = Results.placement result in
    Points.find ~date ~n ~placement


(* Import dancers *)
(* ************************************************************************* *)

let import_dancers ~st file =
  CCIO.with_in file (fun ch ->
      let g = CCIO.read_lines_gen ch in
      Gen.iter (fun s ->
          match split_tsv_line s with
          | None -> ()
          | Some [id; first_name; last_name; birthday; email] ->
            let id = int_of_string id in
            let birthday = if birthday = "" then None else Some (Date.of_string birthday) in
            let email = if email = "" then None else Some email in
            Dancer.import () ~st ~id
              ~first_name ~last_name ?birthday ?email
              ~as_leader:None ~as_follower:None
          | _ ->
            assert false
        ) g
    )


(* Base class for importing an event *)
(* ************************************************************************* *)

class virtual importer (st : State.t) = object(self)

  (* === Auto-correct === *)
  (* ==================== *)

  val max_dist_for_autocorrect = 2
  val mutable index = Dancer.Index.mk ~st
  val mutable new_dancers = []

  method new_dancers = new_dancers

  method find_or_add_dancer ~first_name ~last_name ~event:(_ : Event.id) ?birthday ?email () =
    let first_name = String.trim first_name in
    let last_name = String.trim last_name in
    match Dancer.Index.find ~limit:max_dist_for_autocorrect index ~first_name ~last_name with
    | Found d -> d
    | Not_found { suggestions; } ->
      let add () =
        let d =
          Dancer.add ~st ()
            ?birthday ?email
            ~first_name ~last_name
            ~as_leader:None ~as_follower:None
        in
        index <- Dancer.Index.add d index;
        new_dancers <- d :: new_dancers;
        d
      in
      begin match suggestions with
        | [] -> add ()
        | _ :: _ ->
          let l = List.map (fun d ->
              let n = Str.edit_distance first_name (Dancer.first_name d) in
              let m = Str.edit_distance last_name (Dancer.last_name d) in
              n + m, d
            ) suggestions
          in
          begin match l with
            | [dist, dancer] when dist <= max_dist_for_autocorrect ->
              Logs.warn ~src (fun k->
                  k "Autocorect: %s %s -> %s %s"
                    first_name last_name
                    (Dancer.first_name dancer) (Dancer.last_name dancer));
              dancer
            | _ ->
              let pp_dancer fmt (n, d) =
                Format.fprintf fmt "- (%d) %s %s" n (Dancer.first_name d) (Dancer.last_name d)
              in
              let pp_sep fmt () =
                Format.fprintf fmt "@ "
              in
              Logs.warn ~src (fun k->
                  k "@[<v 2>@[<h>Potentially already existing dancers for '%s %s':@]@ %a@]"
                    first_name last_name (Format.pp_print_list ~pp_sep pp_dancer) l);
              add ()
          end
      end

  (* === Dancers === *)
  (* =============== *)

  method import_bibs ~event:(_:Event.id) (_ : Otoml.t) = ()
  method import_dancers ~event:(_:Event.id) (_ : Otoml.t) = ()


  (* === Phases === *)
  (* ============== *)

  (* Virtual methods: these will be instantiated based on the format version
       of the input file *)
  method virtual import_judges : phase:Phase.t -> Otoml.t -> unit
  method virtual import_heats : phase:Phase.t -> Otoml.t -> unit
  method virtual import_artefacts : event:Event.id -> phase:Phase.t -> Otoml.t -> unit

  method import_phase ~event ~comp ~round t =
    let judge_artefact_descr =
      Otoml.find t Artefact.Descr.of_toml ["judge_artefacts_descr"]
    in
    let head_judge_artefact_descr =
      Otoml.find t Artefact.Descr.of_toml ["head_artefacts_descr"]
    in
    let ranking_algorithm =
      Otoml.find t Ranking.Algorithm.of_toml ["ranking_algorithm"]
    in
    let phase =
      Phase.create ~st (Competition.id comp) round
        ~ranking_algorithm ~judge_artefact_descr ~head_judge_artefact_descr
    in
    self#import_judges ~phase t;
    self#import_heats ~phase t;
    self#import_artefacts ~event ~phase t;
    ()

  method import_phase_opt ~event ~comp ~round t =
    match Otoml.find_opt t Otoml.get_value [Round.toml_key round] with
    | None -> ()
    | Some t -> self#import_phase ~event ~comp ~round t

  method import_phases ~event ~comp t =
    self#import_phase_opt ~event ~comp ~round:Prelims t;
    self#import_phase_opt ~event ~comp ~round:Octofinals t;
    self#import_phase_opt ~event ~comp ~round:Quarterfinals t;
    self#import_phase_opt ~event ~comp ~round:Semifinals t;
    self#import_phase_opt ~event ~comp ~round:Finals t;
    ()

  (* === helper ==== *)
  (* =============== *)

  method check_div_access ~comp (r : Results.r) =
    match Competition.category comp with
    | Non_competitive _ -> ()
    | Competitive comp_div ->
      let dancer = Dancer.get ~st r.dancer in
      let divs =
        match r.role with
        | Leader -> Dancer.as_leader dancer
        | Follower -> Dancer.as_follower dancer
      in
      let effective_divs =
        match divs with
        | None -> Divisions.Novice
        | _ -> divs
      in
      if not (Divisions.includes comp_div effective_divs) then begin
        Logs.err ~src (fun k->
            k "Dancer %a is not allowed to participate in a %a competition"
              Dancer.print dancer Division.print comp_div)
      end

  (* === results === *)
  (* =============== *)

  method virtual parse_results_list :
    event:Event.id -> comp:Competition.t -> Otoml.t -> Results.r list

  method import_results ~event ~comp ?(check_divs=true) t =
    let l = Otoml.find t (self#parse_results_list ~event ~comp) ["results"] in
    List.iter (fun (r : Results.r) ->
        (* Check whether the dancer had access to the division *)
        if check_divs then begin
          self#check_div_access ~comp r
        end;
        Results.add ~st
          ~role:r.role
          ~dancer:r.dancer
          ~result:r.result
          ~points:r.points
          ~competition:r.competition;
        Promotion.update_with_new_result st r
      ) l

  (* === competitions === *)
  (* ==================== *)

  method import_comp ~event t =
    let open Otoml in
    let name = Option.value ~default:"" @@ find_opt t get_string ["name"] in
    let kind = find t Kind.of_toml ["kind"] in
    let category = find t Category.of_toml ["category"] in
    let n_leaders = find t Otoml.get_integer ["leaders"] in
    let n_follows = find t Otoml.get_integer ["follows"] in
    let check_divs = find_opt t Otoml.get_boolean ["check_divs"] in
    let comp =
      match find_opt t get_integer ["id"] with
      | None ->
        Competition.create ~st ()
          ~event_id:event ~name ~kind ~category
          ~n_leaders ~n_follows ?check_divs
      | Some id ->
        Competition.import ~st ~id ()
          ~event_id:event ~name ~kind ~category
          ~n_leaders ~n_follows ?check_divs;
        Competition.get st id
    in
    self#import_bibs ~event t;
    self#import_phases ~event ~comp t;
    self#import_results ~event ~comp ?check_divs t;
    ()

  method import_comps ~event t =
    let l = Otoml.get_table t in
    List.iter (fun (_name, t) -> self#import_comp ~event t) l

  (* === event === *)
  (* ============= *)

  method import_event t =
    let open Otoml in
    let t = Otoml.find t Otoml.get_value ["event"] in
    let name = find t get_string ["name"] in
    let short_name = Option.value ~default:"" (find_opt t get_string ["short"]) in
    let start_date = find t Date.of_toml ["start_date"] in
    let end_date = find t Date.of_toml ["end_date"] in
    let event =
      match find_opt t get_integer ["id"] with
      | None ->
        Event.create ~st ~name ~short_name ~start_date ~end_date
      | Some id ->
        Event.import ~st ~id ~name ~short_name ~start_date ~end_date;
        id
    in
    let t = find t Otoml.get_value ["comps"] in
    self#import_dancers ~event t;
    self#import_comps ~event t;
    event

end


(* Format: FTW version 1 *)
(* ************************************************************************* *)

class ftw_1 st = object(self)

  (* === base class === *)
  (* ================== *)

  inherit importer st

  (* === bibs === *)
  (* ============ *)

  val mutable bibs = Id.Map.empty

  method find_id ~bib =
    try Id.Map.find bib bibs
    with Not_found -> failwith (Format.asprintf "did not find bib %d" bib)

  method! import_bibs ~event t =
    match Otoml.find_opt t Otoml.get_string ["dancers"; "bibs"] with
    | None ->
      Logs.debug ~src (fun k->k "Not bibs found in file, skipping import")
    | Some tsv ->
      Logs.debug ~src (fun k->k "Bibs found, importing...");
      self#import_bibs_tsv ~event tsv
        ~first_name:0 ~last_name:1
        ~leader_bib:2 ~follow_bib:3

  method add_bib_opt bib_opt dancer =
    match bib_opt with
    | None -> ()
    | Some bib -> bibs <- Id.Map.add bib dancer bibs

  method import_bibs_tsv ~event ~first_name ~last_name ~leader_bib ~follow_bib tsv =
    List.iter (fun fields ->
        try
          let leader_bib = extract_bib (List.nth fields leader_bib) in
          let follow_bib = extract_bib (List.nth fields follow_bib) in
          if Option.is_some leader_bib ||
             Option.is_some follow_bib then
            let first_name = List.nth fields first_name in
            let last_name = List.nth fields last_name in
            let dancer =
              self#find_or_add_dancer ()
                ~first_name ~last_name ~event
            in
            self#add_bib_opt leader_bib (Dancer.id dancer);
            self#add_bib_opt follow_bib (Dancer.id dancer);
            ()
        with Failure msg ->
          let line = String.concat "\t" fields in
          Logs.err (fun k->k "Ignoring line in dancers tsv: '%s' (error: %s)(fields: %d)" line msg (List.length fields));
          ()
      ) (split_tsv tsv)


  (* === heats & artefacts === *)
  (* ========================= *)

  (* heats and judge panels are created based on the artefacts, so this does nothing *)
  method import_judges ~phase:_ _ = ()
  method import_heats ~phase:_ _ = ()

  method find_judge ~event s =
    assert (String.length s > 0);
    let find_id s =
      match String.split_on_char ',' s with
      | [first_name; last_name] ->
        Dancer.id (self#find_or_add_dancer ~event ~first_name ~last_name ())
      | _ ->
        Logs.err (fun k->k "Could not parse judge: '%s'" s);
        assert false
    in
    match s with
    | "Bonus" -> Bonus
    | _ when (String.length s > 0 && s.[0] = '*') ->
      let s = String.sub s 1 (String.length s - 1) in
      Head (find_id s)
    | _ ->
      Judge (find_id s)

  method parse_judges ~event = function
    | [] -> []
    | "" :: r -> self#parse_judges ~event r
    | s :: r -> self#find_judge ~event s :: self#parse_judges ~event r

  method parse_one_artefact ~descr scores =
    match (descr: Artefact.Descr.t) with
    | Ranking ->
      begin match scores with
        | s :: scores -> Artefact.Rank (int_of_string s), scores
        | _ ->
          Logs.err ~src (fun k->k "Missing artefacts");
          assert false
      end
    | Yans { criterion; } ->
      let n = List.length criterion in
      let l, scores = CCList.take_drop n scores in
      assert (List.length l = n);
      let l = List.map yan_of_note l in
      Artefact.Yans l, scores

  method parse_artefacts ~event ~judge_artefact_descr ~head_artefact_descr acc judges scores =
    match judges with
    (* order should not matter *)
    | [] -> acc, None
    | [Bonus] ->
      begin match scores with
        | [note] -> acc, Some (bonus_of_note note)
        | _ -> Logs.err ~src (fun k->k "Missing artefacts"); assert false
      end
    | Bonus :: _ :: _ ->
      Logs.err ~src (fun k->k "Bonus should be last"); assert false
    | Judge judge :: judges ->
      let artefact, scores = self#parse_one_artefact ~descr:judge_artefact_descr scores in
      self#parse_artefacts ~event
        ~judge_artefact_descr ~head_artefact_descr
        ((judge, artefact) :: acc) judges scores
    | Head judge :: judges ->
      let artefact, scores = self#parse_one_artefact ~descr:head_artefact_descr scores in
      self#parse_artefacts ~event
        ~judge_artefact_descr ~head_artefact_descr
        ((judge, artefact) :: acc) judges scores

  (* === Prelim artefacts === *)

  method parse_judges_and_artefacts : type a.
    event:Event.id ->
    judge_artefact_descr:Artefact.Descr.t ->
    head_artefact_descr:Artefact.Descr.t ->
    split:(string list -> (a * string list) option) ->
    Otoml.t ->
    judge list * (a * ((Judge.id * Artefact.t) list * Bonus.t option)) list
    = fun ~event ~judge_artefact_descr ~head_artefact_descr ~split t ->
    let l = split_tsv ~comments:false (Otoml.get_string t) in
    (* Get the list of judges *)
    let judges, l =
      match l with
      | judges :: _ :: r -> self#parse_judges ~event judges, r
      | _ ->
        Logs.err (fun k->k "Could not parse the list of judges (%d)" (List.length l));
        assert false
    in
    (* Parse artefacts *)
    let artefacts =
      List.filter_map (fun line ->
          match split line with
          | Some (id, scores) ->
            let artefacts = self#parse_artefacts [] judges scores
                ~event ~judge_artefact_descr ~head_artefact_descr
            in
            Some (id, artefacts)
          | None -> None
        ) l
    in
    judges, artefacts

  method import_singles_artefacts ~event ~phase t =
    let judge_artefact_descr = Phase.judge_artefact_descr phase in
    let head_artefact_descr = Phase.head_judge_artefact_descr phase in
    let phase = Phase.id phase in
    let split = function
      | _rank :: bib :: _name :: _total :: scores ->
        let id : Id.t = self#find_id ~bib:(int_of_string bib) in
        Some (id, scores)
      | _ -> None
    in
    let leader_judges, leader_artefacts =
      Otoml.find t (
        self#parse_judges_and_artefacts ~event ~split
          ~judge_artefact_descr ~head_artefact_descr
      ) ["leaders_artefacts"]
    in
    let follow_judges, follow_artefacts =
      Otoml.find t (
        self#parse_judges_and_artefacts ~event ~split
          ~judge_artefact_descr ~head_artefact_descr
      ) ["followers_artefacts"]
    in
    (* Set judges *)
    let panel = make_singles_panel leader_judges follow_judges in
    Judge.set ~st ~phase panel;
    (* add notes *)
    let add_heat_and_artefact ~role (dancer_id, (artefacts, bonus)) =
      let target = Heat.add_single ~st ~phase ~heat:1 ~role dancer_id in
      List.iter (fun (judge, artefact) ->
          Artefact.set ~st ~judge ~target artefact
        ) artefacts;
      match bonus with
      | None -> ()
      | Some b -> Bonus.set ~st ~target b
    in
    List.iter (add_heat_and_artefact ~role:Leader) leader_artefacts;
    List.iter (add_heat_and_artefact ~role:Follower) follow_artefacts;
    ()

  (* === Finals artefacts === *)

  method import_couples_artefacts ~event ~phase t =
    let judge_artefact_descr = Phase.judge_artefact_descr phase in
    let head_artefact_descr = Phase.head_judge_artefact_descr phase in
    let phase = Phase.id phase in
    let split = function
      | leader :: follower :: ranks ->
        let leader_id = self#find_id ~bib:(extract_bib' leader) in
        let follow_id = self#find_id ~bib:(extract_bib' follower) in
        Some ((leader_id, follow_id), ranks)
      | _ -> None
    in
    let judges, artefacts =
      Otoml.find t (
        self#parse_judges_and_artefacts ~event ~split
          ~judge_artefact_descr ~head_artefact_descr
      ) ["artefacts"]
    in
    let panel = make_couples_panel judges in
    Judge.set ~st ~phase panel;
    (* add notes *)
    let add_heat_and_artefact ((leader, follower), (artefacts, bonus)) =
      let target = Heat.add_couple ~st ~phase ~heat:1 ~leader ~follower in
      List.iter (fun (judge, artefact) ->
          Artefact.set ~st ~judge ~target artefact
        ) artefacts;
      match bonus with
      | None -> ()
      | Some b -> Bonus.set ~st ~target b
    in
    List.iter add_heat_and_artefact artefacts

  method import_artefacts ~event ~phase t =
    let comp = Competition.get st (Phase.competition phase) in
    match Competition.kind comp, Phase.round phase with
    | Jack_and_Jill, (Prelims | Octofinals | Quarterfinals | Semifinals) ->
      self#import_singles_artefacts ~event ~phase t
    | Jack_and_Jill, Finals ->
      self#import_couples_artefacts ~event ~phase t
    | (Routine | Strictly | JJ_Strictly), _ ->
      Logs.warn ~src (fun k->k "Artefacts import not implemented yet for non-J&J")


  (* === competition results === *)
  (* =========================== *)

  method parse_results_row ~event ~comp ~res ~role ~last_name ~first_name () =
    let d = self#find_or_add_dancer ~event ~first_name ~last_name () in
    let result =
      match res with
      | "F" -> Results.finalist
      | "S" -> Results.semifinalist
      | "Q" -> Results.quarterfinalist
      | "E" -> Results.octofinalist
      | _ ->
        begin match int_of_string res with
          | i -> Results.mk ~finals:(Ranked i) ()
          | exception Failure _ ->
            raise (Otoml.Type_error ("invalid result: " ^ res))
        end
    in
    let role =
      match role with
      | "L" -> Role.Leader
      | "F" -> Role.Follower
      | _ -> raise (Otoml.Type_error ("invalid role: " ^ role))
    in
    let points = points ~st ~event ~comp ~role result in
    let r : Results.r = {
      competition = (Competition.id comp);
      dancer = Dancer.id d;
      role; result; points;
    }
    in
    r

  method parse_results_list ~event ~comp t =
    let contents = Otoml.get_string t in
    let lines = String.split_on_char '\n' contents in
    let l =
      List.fold_left (fun acc line ->
          let line = String.trim line in
          if String.length line <= 0 || line.[0] = '#' then acc
          else
            let r =
              match String.split_on_char '\t' line with
              | res :: role :: last_name :: first_name :: ([] | _ :: []) ->
                self#parse_results_row ~event ~comp ~res ~role ~last_name ~first_name ()
              | _ ->
                Logs.err ~src (fun k->k "error in result !");
                raise (Otoml.Type_error (Format.asprintf  "not a valid result: '%s'" line))
            in
            r :: acc
        ) [] lines
    in
    l


end

(* Format: FTW version 2 *)
(* ************************************************************************* *)

class ftw_2 st ~stable = object(self)

  (* === base class === *)
  (* ================== *)

  inherit importer st

  (* === new dancers === *)
  (* =================== *)

  val mutable dancer_map = Id.Map.empty

  method! import_dancers ~event:(_: Event.id) t =
    if stable then
      (* stable format for long-term archive relies on an external list of
         dancers with stable ids, so the file should use dancer id and never bibs *)
      ()
    else begin
      match Otoml.find_opt t (Otoml.get_array Dancer.of_toml) ["dancers"] with
      | None -> ()
      | Some l ->
        List.iter (fun d ->
            let stable_dancer =
              Dancer.add ~st ()
                ?email:(Dancer.email d)
                ?birthday:(Dancer.birthday d)
                ~last_name:(Dancer.last_name d)
                ~first_name:(Dancer.first_name d)
                ~as_leader:None ~as_follower:None
            in
            dancer_map <- Id.Map.add (Dancer.id d) (Dancer.id stable_dancer) dancer_map
          ) l
    end

  method get_dancer id_in_file =
    if stable then id_in_file
    else begin
      match Id.Map.find_opt id_in_file dancer_map with
      | Some id -> id
      | None ->
        begin match Dancer.get ~st id_in_file with
          | _ -> id_in_file
          | exception Not_found -> failwith (Format.asprintf "dancer id not in db: %d" id_in_file)
        end
    end

  (* === judge panel === *)
  (* =================== *)


  method import_judges ~phase t =
    let comp = Competition.get st (Phase.competition phase) in
    let panel = Otoml.find_exn t Judge.panel_of_toml ["judges"] in
    match Competition.kind comp, Phase.round phase, panel with
    | Jack_and_Jill, (Prelims | Octofinals | Quarterfinals | Semifinals), Singles _
    | Jack_and_Jill, Finals, Couples _
    | (Routine | Strictly | JJ_Strictly), _, Couples _ ->
      Judge.set ~st ~phase:(Phase.id phase) panel
    | _ ->
      Logs.err ~src (fun k->k "Incoherent judge panel for phase")

  (* === heats & artefacts === *)
  (* ========================= *)

  val mutable heat_target_map = Id.Map.empty

  method import_heats ~phase t =
    let comp = Competition.get st (Phase.competition phase) in
    match Competition.kind comp, Phase.round phase with
    | Jack_and_Jill, (Prelims | Octofinals | Quarterfinals | Semifinals) ->
      let heats = Otoml.find_exn t Heat.singles_heats_of_toml ["heats"] in
      let aux ~heat ~role (single : Heat.single) =
        let new_id =
          Heat.add_single
            ~st ~phase:(Phase.id phase)
            ~heat ~role single.dancer
        in
        heat_target_map <- Id.Map.add single.target_id new_id heat_target_map
      in
      Array.iteri (fun heat (singles_heat : Heat.singles_heat) ->
          List.iter (aux ~heat ~role:Leader) singles_heat.leaders;
          List.iter (aux ~heat ~role:Follower) singles_heat.followers
        ) heats.singles_heats
    | Jack_and_Jill, Finals
    | (Routine | Strictly | JJ_Strictly), _ ->
      let heats = Otoml.find_exn t Heat.couples_heats_of_toml ["heats"] in
      Array.iteri (fun heat (couples_heat : Heat.couples_heat) ->
          List.iter (fun (couple : Heat.couple) ->
              let new_id =
                Heat.add_couple
                  ~st ~phase:(Phase.id phase)
                  ~heat ~leader:couple.leader ~follower:couple.follower
              in
              heat_target_map <- Id.Map.add couple.target_id new_id heat_target_map
            ) couples_heat.couples
        ) heats.couples_heats

  method import_artefacts ~event:_ ~phase t =
    let aux descr field =
      let parse = Otoml.get_array (Artefact.Targeted.of_toml ~descr) in
      let l = Otoml.find_exn t parse [field] in
      List.iter (fun ({ judge; target; artefact; } : Artefact.Targeted.t) ->
          let new_id = Id.Map.find target heat_target_map in
          Artefact.set ~st ~judge ~target:new_id artefact
        ) l
    in
    aux (Phase.head_judge_artefact_descr phase) "head_artefacts";
    aux (Phase.judge_artefact_descr phase) "judge_artefacts";
    ()


  (* === competition results === *)
  (* =========================== *)

  method parse_results_list ~event ~comp t =
    Otoml.get_array (fun t ->
        let raw_dancer = Otoml.find t Id.of_toml ["dancer"] in
        let dancer = self#get_dancer raw_dancer in
        let role = Otoml.find t Role.of_toml ["role"] in
        let result = Otoml.find t Results.of_toml ["result"] in
        let points = points ~st ~event ~comp ~role result in
        let r : Results.r = {
          competition = (Competition.id comp);
          dancer; role; result; points;
        } in
        r
      ) t

end

(* Import from a single file *)
(* ************************************************************************* *)

let from_file ~st acc path =
  let+ prev_ids = acc in
  let start_time = Unix.gettimeofday () in
  Logs.debug ~src (fun k->k "%s : reading input file..." (Filename.basename path));
  let+ t = Otoml.Parser.from_file_result path in
  try
    let importer : importer =
      match Otoml.find t Otoml.get_string ["config"; "format"] with
      | "ftw.1" -> (new ftw_1 st :> importer)
      | "ftw.2" -> (new ftw_2 st ~stable:false :> importer)
      | "ftw.2-stable" -> (new ftw_2 st ~stable:true :> importer)
      | _ -> assert false
    in
    let ev_id = importer#import_event t in
    let new_dancers = importer#new_dancers in
    let stop_time = Unix.gettimeofday () in
    Logs.info ~src (fun k->k "%s : finished import in %.4fs"
                       (Filename.basename path) (stop_time -. start_time));
    Ok ((ev_id, new_dancers) :: prev_ids)
  with exn ->
    let bt = Printexc.get_backtrace () in
    Logs.err ~src (fun k->
        k "Import failed due to exception: %s@\n@[<h>%a@]"
          (Printexc.to_string exn) Format.pp_print_text bt
      );
    Error "Exception while importing"


(* File/Directory interaction *)
(* ************************************************************************* *)

let list_files path =
  let all_files = Gen.to_list @@ CCIO.File.read_dir ~recurse:true (CCIO.File.make path) in
  let files = List.filter (fun file_path -> Filename.extension file_path = ".toml") all_files in
  List.sort (fun f1 f2 ->
      String.compare (Filename.basename f1) (Filename.basename f2)
    ) files

let import_event ~st path =
  List.fold_left (from_file ~st) (Ok []) (list_files path)

