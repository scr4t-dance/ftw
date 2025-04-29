
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw.export"

type dancer_export =
  | Internal
  | External of { dancer_file : string; }

(* Dancers & bibs *)
(* ************************************************************************* *)

let append_dancers file l =
  let ch = open_out_gen [Open_append; Open_creat; Open_text] 0o644 file in
  let fmt = Format.formatter_of_out_channel ch in
  let l = List.sort (fun d d' -> Id.compare (Dancer.id d) (Dancer.id d')) l in
  List.iter (fun d ->
      Format.fprintf fmt "%d	%s	%s	%s	%s@\n"
        (Dancer.id d)
        (Dancer.first_name d) (Dancer.last_name d)
        (match Dancer.birthday d with None -> "" | Some date -> Date.to_string date)
        (match Dancer.email d with None -> "" | Some email -> email)
    ) l


(* Results *)
(* ************************************************************************* *)

let export_results ~st comp =
  let results = Results.find ~st (`Competition (Competition.id comp)) in
  [ "results", Otoml.array (List.map (fun (res : Results.r) ->
        Otoml.inline_table [
          "dancer", Id.to_toml res.dancer;
          "role", Role.to_toml res.role;
          "result", Results.to_toml res.result;
        ]) results)
  ]

(* Phases *)
(* ************************************************************************* *)

let all_singles_artefacts ~st ~phase ~judge_artefacts ~head_artefacts (heats : Heat.singles_heats) =
  let aux ~judging ~descr judge =
    let aux ({ target_id = target; dancer = _; } : Heat.single) =
      let artefact = Artefact.get ~descr ~st ~judge ~target in
      Artefact.Targeted.to_toml { judge; target; artefact; }
    in
    List.concat_map (fun (heat : Heat.singles_heat) ->
        match (judging : Judging.t) with
        | Head ->
          List.map aux heat.leaders @
          List.map aux heat.followers
        | Leaders ->
          List.map aux heat.leaders
        | Followers ->
          List.map aux heat.followers
        | Couples ->
          assert false
      ) (Array.to_list heats.singles_heats)
  in
  match Judge.get ~st ~phase with
  | Couples _ -> assert false
  | Singles { leaders; followers; head; } ->
    Otoml.array (
      List.concat_map (aux ~judging:Leaders ~descr:judge_artefacts) leaders @
      List.concat_map (aux ~judging:Followers ~descr:judge_artefacts) followers
    ),
    Otoml.array (
      Option.fold ~none:[] ~some:(aux ~judging:Head ~descr:head_artefacts) head
    )

let all_couples_artefacts ~st ~phase ~judge_artefacts ~head_artefacts (heats : Heat.couples_heats) =
  let aux ~judging ~descr judge =
    let aux ({ target_id = target; leader = _; follower = _; } : Heat.couple) =
      let artefact = Artefact.get ~descr ~st ~judge ~target in
      Artefact.Targeted.to_toml { judge; target; artefact; }
    in
    List.concat_map (fun (heat : Heat.couples_heat) ->
        match (judging : Judging.t) with
        | Head | Couples ->
          List.map aux heat.couples
        | Leaders | Followers ->
          assert false
      ) (Array.to_list heats.couples_heats)
  in
  match Judge.get ~st ~phase with
  | Couples { couples; head; } ->
    Otoml.array (
      List.concat_map (aux ~judging:Couples ~descr:judge_artefacts) couples
    ),
    Otoml.array (
      Option.fold ~none:[] ~some:(aux ~judging:Head ~descr:head_artefacts) head
    )
  | Singles _ ->
    assert false

let export_phase ~st ~kind phase =
  let judge_artefacts = Phase.judge_artefact_descr phase in
  let head_artefacts = Phase.head_judge_artefact_descr phase in
  let ranking_algorithm = Phase.ranking_algorithm phase in
  let judge_panel = Judge.get ~st ~phase:(Phase.id phase) in
  let heats_toml, judge_artefacts_toml, head_artefacts_toml =
    match (kind : Kind.t), Phase.round phase with
    | Jack_and_Jill, Finals ->
      let heats = Heat.get_couples ~st ~phase:(Phase.id phase) in
      let heats_toml = Heat.couples_heats_to_toml heats in
      let judge_artefacts_toml, head_artefacts_toml =
        all_couples_artefacts ~st ~phase:(Phase.id phase) ~judge_artefacts ~head_artefacts heats
      in
      heats_toml, judge_artefacts_toml, head_artefacts_toml
    | Jack_and_Jill, ( Prelims | Octofinals | Quarterfinals | Semifinals ) ->
      let heats = Heat.get_singles ~st ~phase:(Phase.id phase) in
      let heats_toml = Heat.singles_heats_to_toml heats in
      let judge_artefacts_toml, head_artefacts_toml =
        all_singles_artefacts ~st ~phase:(Phase.id phase) ~judge_artefacts ~head_artefacts heats
      in
      heats_toml, judge_artefacts_toml, head_artefacts_toml
    | _ -> assert false
  in
  let t = Otoml.table [
      "judge_artefacts_descr", Artefact.Descr.to_toml judge_artefacts;
      "head_artefacts_descr", Artefact.Descr.to_toml head_artefacts;
      "ranking_algorithm", Ranking.Algorithm.to_toml ranking_algorithm;
      "judges", Judge.panel_to_toml judge_panel;
      "heats", heats_toml;
      "head_artefacts", head_artefacts_toml;
      "judge_artefacts", judge_artefacts_toml;
    ]
  in
  let toml_key = Round.toml_key (Phase.round phase) in
  toml_key, t

let export_phases ~st ~kind phases =
  Logs.debug ~src (fun k->k "Starting phases export...");
  let l = List.map (export_phase ~st ~kind) phases in
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
      | Routine, Non_competitive Regular -> "cc"
      | _ -> Format.asprintf "comp%d" (Competition.id comp)
    end
  | s -> s

let export_comp ~st comp =
  Logs.debug ~src (fun k->k "Exporting competition %d" (Competition.id comp));
  let results_fields = export_results ~st comp in
  let phases = Phase.find st (Competition.id comp) in
  let phases_fields = export_phases ~st ~kind:(Competition.kind comp) phases in
  let t = Otoml.table (
      ("id", Otoml.integer (Competition.id comp)) ::
      ("name", Otoml.string (Competition.name comp)) ::
      ("kind", Kind.to_toml (Competition.kind comp)) ::
      ("category", Category.to_toml (Competition.category comp)) ::
      ("leaders", Otoml.integer (Competition.n_leaders comp)) ::
      ("follows", Otoml.integer (Competition.n_follows comp)) ::
      ("check_divs", Otoml.boolean (Competition.check_divs comp)) ::
      results_fields @
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

let event_toml ~st ~local event_id =
  Logs.debug ~src (fun k->k "Exporting event %d" event_id);
  let format = if not local then "ftw.2" else assert false (* TODO: add local event export *) in
  let event = Event.get st event_id in
  let comps = Competition.from_event st event_id in
  let comp_fields = export_comps ~st comps in
  let id = Otoml.integer (Event.id event) in
  let name = Otoml.string (Event.name event) in
  let short_name = Otoml.string (Event.short_name event) in
  let start_date = Date.to_toml (Event.start_date event) in
  let end_date = Date.to_toml (Event.end_date event) in
  Otoml.table [
    "config", Otoml.table [
      "format", Otoml.string format;
    ];
    "event", Otoml.table (
      ("id", id) ::
      ("name", name) ::
      ("short", short_name) ::
      ("start_date", start_date) ::
      ("end_date", end_date) ::
      comp_fields
    );
  ]

let export_event ~st path event_id =
  try
    let toml = event_toml ~st ~local:false event_id in
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

