
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Misc.Result
let src = Logs.Src.create "ftw.import"

(* Phases *)
(* ************************************************************************* *)

let import_phase ~st ~t ~comp_id round =
  let+ judge_artefact_descr =
    Otoml.find_result t Artefact.Descr.of_toml ["artefacts"]
  in
  let+ head_judge_artefact_descr =
    Otoml.find_result t Artefact.Descr.of_toml ["head_artefacts"]
  in
  let+ ranking_algorithm =
    Otoml.find_result t Ranking.Algorithm.of_toml ["ranking_algorithm"]
  in
  let _phase_id =
    Phase.create ~st comp_id round
      ~ranking_algorithm ~judge_artefact_descr ~head_judge_artefact_descr
  in
  Ok ()

let import_phases ~st ~t ~comp_id =
  let aux round =
    match Otoml.find_opt t Otoml.get_value [Round.toml_key round] with
    | None -> Ok ()
    | Some t -> import_phase ~st ~t ~comp_id round
  in
  let+ () = aux Prelims in
  let+ () = aux Octofinals in
  let+ () = aux Quarterfinals in
  let+ () = aux Semifinals in
  let+ () = aux Finals in
  Ok ()


(* Competitions *)
(* ************************************************************************* *)

let import_comp ~st ~t ~event_id =
  let open Otoml in
  let name = Option.value ~default:"" @@ find_opt t get_string ["name"] in
  let+ kind = find_result t Kind.of_toml ["kind"] in
  let+ category = find_result t Category.of_toml ["category"] in
  let _comp_id = Competition.create st event_id name kind category in
  Ok ()

let import_comps ~st ~t ~event_id =
  let+ l = Otoml.get_result Otoml.get_table t in
  List.fold_left (fun acc (_name, t) ->
      let+ () = acc in import_comp ~st ~t ~event_id
    ) (Ok ()) l

(* Event *)
(* ************************************************************************* *)

let import_event ~st ~t =
  let open Otoml in
  let+ name = find_result t get_string ["name"] in
  let+ start_date = find_result t Date.of_toml ["start_date"] in
  let+ end_date = find_result t Date.of_toml ["end_date"] in
  let event_id = Event.create st name ~start_date ~end_date in
  let+ t = find_result t Otoml.get_value ["comps"] in
  import_comps ~st ~t ~event_id


(* File interaction *)
(* ************************************************************************* *)

let from_file st path =
  let+ t = Otoml.Parser.from_file_result path in
  try
    Logs.app ~src (fun k->k "Read input file from %s" path);
    let+ t_ev = Otoml.find_result t Otoml.get_value ["event"] in
    import_event ~st ~t:t_ev
  with exn ->
    let bt = Printexc.get_backtrace () in
    Logs.err ~src (fun k->
        k "Import failed due to exception: %s@\n@[<h>%a@]"
          (Printexc.to_string exn) Format.pp_print_text bt
      );
    Error "Exception while importing"


