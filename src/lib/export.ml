
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw.export"

(* Phases *)
(* ************************************************************************* *)

let export_phase ~st:_ phase =
  let artefacts = Phase.judge_artefact_descr phase in
  let head_artefacts = Phase.head_judge_artefact_descr phase in
  let ranking_algorithm = Phase.ranking_algorithm phase in
  let t = Otoml.table [
      "judge_artefacts_descr", Artefact.Descr.to_toml artefacts;
      "head_artefacts_descr", Artefact.Descr.to_toml head_artefacts;
      "ranking_algorithm", Ranking.Algorithm.to_toml ranking_algorithm;
    ]
  in
  let toml_key = Round.toml_key (Phase.round phase) in
  toml_key, t

let export_phases ~st phases =
  Logs.debug ~src (fun k->k "Starting phases export...");
  let l = List.map (export_phase ~st) phases in
  l

(* Competitions *)
(* ************************************************************************* *)

let comp_name comp =
  match Competition.name comp with
  | "" ->
    begin match Competition.kind comp, Competition.category comp with
      | Jack_and_Jill, Competitive Novice -> "jj_novice"
      | Jack_and_Jill, Competitive Intermediate -> "jj_inter"
      | Jack_and_Jill, Competitive Advanced -> "jj_advanced"
      | _ -> Format.asprintf "comp_%d" (Competition.id comp)
    end
  | s -> s

let export_comp ~st comp =
  Logs.debug ~src (fun k->k "Exporting competition %d" (Competition.id comp));
  let phases = Phase.find st (Competition.id comp) in
  let phases_fields = export_phases ~st phases in
  let t = Otoml.table (
      ("name", Otoml.string (Competition.name comp)) ::
      ("kind", Kind.to_toml (Competition.kind comp)) ::
      ( "category", Category.to_toml (Competition.category comp)) ::
      phases_fields
    )
  in
  comp_name comp, t

let export_comps ~st comps =
  Logs.debug ~src (fun k->k "Starting competitions export...");
  let l = List.map (export_comp ~st) comps in
  ["comps", Otoml.table l]


(* Events *)
(* ************************************************************************* *)

let export_event ~st event_id =
  Logs.debug ~src (fun k->k "Exporting event %d" event_id);
  let event = Event.get st event_id in
  let comps = Competition.from_event st event_id in
  let comp_fields = export_comps ~st comps in
  let name = Otoml.string (Event.name event) in
  let start_date = Date.to_toml (Event.start_date event) in
  let end_date = Date.to_toml (Event.end_date event) in
  Otoml.table [
    "event", Otoml.table (
      ("name", name) ::
      ("start_date", start_date) ::
      ("end_date", end_date) ::
      comp_fields
    )
  ]

(* File interaction *)
(* ************************************************************************* *)

let to_file ~st path event_id =
  try
    let toml = export_event ~st event_id in
    Logs.debug ~src (fun k->k "Finished collating data, writing to file %s" path);
    let ch = open_out path in
    Otoml.Printer.to_channel ch toml
      ~indent_width:2
      ~indent_character:' '
      ~indent_subtables:false
      ~newline_before_table:true
      ~force_table_arrays:false
    ;
    close_out ch;
    Ok ()
  with exn ->
    let bt = Printexc.get_backtrace () in
    Logs.err ~src (fun k->
        k "Export failed due to exception:%s@\n@[<h>%a@]"
          (Printexc.to_string exn) Format.pp_print_text bt
      );
    Error ()

