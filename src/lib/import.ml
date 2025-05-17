
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Misc.Result
let src = Logs.Src.create "ftw.import"

(* Global state & configuration for import *)
(* ************************************************************************* *)

let max_dist_for_autocorrect = 2

let index = ref Dancer.Index.empty

(* Dancers *)
(* ************************************************************************* *)

(* *)
let find_or_add_dancer ~st
    ~first_name ~last_name
    ?birthday ?email () =
  match Dancer.Index.find !index ~first_name ~last_name with
  | Found d -> d
  | Not_found { suggestions; } ->
    let add () =
      let d =
        Dancer.add ~st ()
          ?birthday ?email ~first_name ~last_name
          ~as_leader:None ~as_follower:None
      in
      index := Dancer.Index.add d !index;
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

let import_dancers_aux ~st ~t =
  let+ l = Otoml.find_result t (Otoml.get_array Otoml.get_value) ["list"] in
  let map =
    List.fold_left (fun map t' ->
        let file_id = Otoml.find t' Otoml.get_integer ["id"] in
        let first_name = Otoml.find t' Otoml.get_string ["first_name"] in
        let last_name = Otoml.find t' Otoml.get_string ["last_name"] in
        let birthday = Otoml.find_opt t' Date.of_toml ["dob"] in
        let email = Otoml.find_opt t' Otoml.get_string ["email"] in
        let dancer =
          find_or_add_dancer ~st ()
            ?birthday ?email ~first_name ~last_name
        in
        Id.Map.add file_id (Dancer.id dancer) map
      ) Id.Map.empty l
  in
  Ok map

let import_dancers ~st t =
  let t = Otoml.find_opt t Otoml.get_value ["dancers"] in
  match t with
  | None -> Ok Id.Map.empty
  | Some t -> import_dancers_aux ~st ~t

(* Phases *)
(* ************************************************************************* *)

let import_phase ~st ~subst:_ ~t ~competition round =
  let+ judge_artefact_descr =
    Otoml.find_result t Artefact.Descr.of_toml ["judge_artefacts_descr"]
  in
  let+ head_judge_artefact_descr =
    Otoml.find_result t Artefact.Descr.of_toml ["head_artefacts_descr"]
  in
  let+ ranking_algorithm =
    Otoml.find_result t Ranking.Algorithm.of_toml ["ranking_algorithm"]
  in
  let _phase_id =
    Phase.create ~st (Competition.id competition) round
      ~ranking_algorithm ~judge_artefact_descr ~head_judge_artefact_descr
  in
  Ok ()

let import_phases ~st ~subst ~t ~competition =
  let aux round =
    match Otoml.find_opt t Otoml.get_value [Round.toml_key round] with
    | None -> Ok ()
    | Some t -> import_phase ~st ~subst ~t ~competition round
  in
  let+ () = aux Prelims in
  let+ () = aux Octofinals in
  let+ () = aux Quarterfinals in
  let+ () = aux Semifinals in
  let+ () = aux Finals in
  Ok ()


(* Results *)
(* ************************************************************************* *)

let import_results_csv ~st ~competition t =
  (* Parse and import a row, i.e. one results *)
  let parse_row ~res ~role ~last_name ~first_name () =
    let first_name = String.trim first_name in
    let last_name = String.trim last_name in
    let d = find_or_add_dancer ~st ~first_name ~last_name () in
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
    (* TODO: implement point computation for competitions in Points *)
    let points = 0 in
    let r : Results.r = {
      competition = Competition.id competition;
      dancer = Dancer.id d;
      role; result; points;
    }
    in
    r
  in
  (* *)
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
              parse_row ~res ~role ~last_name ~first_name ()
            | _ ->
              Logs.err ~src (fun k->k "error in result !");
              raise (Otoml.Type_error (Format.asprintf  "not a valid result: '%s'" line))
          in
          r :: acc
      ) [] lines
  in
  l

let import_results_list ~subst ~competition t =
  Otoml.get_array (fun t ->
      let dancer_before_subst = Otoml.find t Id.of_toml ["dancer"] in
      let dancer = Id.Map.find dancer_before_subst subst in
      let role = Otoml.find t Role.of_toml ["role"] in
      let result = Otoml.find t Results.of_toml ["result"] in
      (* TODO: points *)
      let points = 0 in
      let r : Results.r = {
        competition = Competition.id competition;
        dancer; role; result; points;
      } in
      r
    ) t


let import_results ~st ~subst ~t ~competition =
  let t = Otoml.find t Otoml.get_value ["results"] in
  let results =
    match Otoml.find_opt t (import_results_csv ~st ~competition) ["csv"] with
    | Some l -> l
    | None ->
      begin match Otoml.find_opt t (import_results_list ~subst ~competition) ["list"] with
        | Some l -> l
        | None -> raise (Otoml.Type_error "Missing results")
      end
  in
  List.iter (fun (r : Results.r) ->
      Results.add ~st
        ~role:r.role
        ~dancer:r.dancer
        ~result:r.result
        ~points:r.points
        ~competition:r.competition
    ) results;
  Ok ()

(* Competitions *)
(* ************************************************************************* *)

let import_comp ~st ~subst ~t ~event_id =
  let open Otoml in
  let name = Option.value ~default:"" @@ find_opt t get_string ["name"] in
  let+ kind = find_result t Kind.of_toml ["kind"] in
  let+ category = find_result t Category.of_toml ["category"] in
  let+ n_leaders = find_result t Otoml.get_integer ["leaders"] in
  let+ n_follows = find_result t Otoml.get_integer ["follows"] in
  let check_divs = find_opt t Otoml.get_boolean ["check_divs"] in
  let competition =
    Competition.create st
      event_id name kind category
      ~n_leaders ~n_follows ?check_divs
  in
  let+ () = import_phases ~st ~subst ~t ~competition in
  let+ () = import_results ~st ~subst ~t ~competition in
  Ok ()

let import_comps ~st ~subst ~t ~event_id =
  let+ l = Otoml.get_result Otoml.get_table t in
  List.fold_left (fun acc (_name, t) ->
      let+ () = acc in import_comp ~st ~subst ~t ~event_id
    ) (Ok ()) l

(* Event *)
(* ************************************************************************* *)

let import_event_aux ~st ~subst ~t =
  let open Otoml in
  let+ name = find_result t get_string ["name"] in
  let+ start_date = find_result t Date.of_toml ["start_date"] in
  let+ end_date = find_result t Date.of_toml ["end_date"] in
  let event_id = Event.create st name ~start_date ~end_date in
  let+ t = find_result t Otoml.get_value ["comps"] in
  import_comps ~st ~subst ~t ~event_id

let import_event ~st ~subst ~t =
  let t = Otoml.find_opt t Otoml.get_value ["event"] in
  match t with
  | None -> Ok ()
  | Some t -> import_event_aux ~st ~subst ~t


(* Import from a single file *)
(* ************************************************************************* *)

let from_file ~st acc path =
  let+ () = acc in
  let start_time = Unix.gettimeofday () in
  Logs.debug ~src (fun k->k "%s : reading input file..." (Filename.basename path));
  let+ t = Otoml.Parser.from_file_result path in
  try
    index := Dancer.Index.mk ~st;
    let+ subst = import_dancers ~st t in
    let+ () = import_event ~st ~subst ~t in
    let stop_time = Unix.gettimeofday () in
    Logs.info ~src (fun k->k "%s : finished import in %.4fs"
                       (Filename.basename path) (stop_time -. start_time));
    Ok ()
  with exn ->
    let bt = Printexc.get_backtrace () in
    Logs.err ~src (fun k->
        k "Import failed due to exception: %s@\n@[<h>%a@]"
          (Printexc.to_string exn) Format.pp_print_text bt
      );
    Error "Exception while importing"

(* File/Directory interaction *)
(* ************************************************************************* *)

let import ~st path =
  let all_files = Gen.to_list @@ CCIO.File.read_dir ~recurse:true (CCIO.File.make path) in
  let files = List.filter (fun file_path -> Filename.extension file_path = ".toml") all_files in
  let sorted_files =
    List.sort (fun f1 f2 ->
        String.compare (Filename.basename f1) (Filename.basename f2)
      ) files
  in
  List.fold_left (from_file ~st) (Ok ()) sorted_files

