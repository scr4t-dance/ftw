
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t

type singles = {
  leaders : Dancer.id list;
  followers : Dancer.id list;
  head : Dancer.id option;
}

type couples = {
  couples : Dancer.id list;
  head : Dancer.id option;
}

type panel =
  | Singles of singles
  | Couples of couples


(* Serialization *)
(* ************************************************************************* *)

let singles_to_toml { leaders; followers; head; } =
  Otoml.inline_table (
    ("leaders", Otoml.array (List.map Id.to_toml leaders)) ::
    ("followers", Otoml.array (List.map Id.to_toml followers)) ::
    (match head with
     | None -> []
     | Some id -> ["head", Id.to_toml id])
  )

let singles_of_toml t =
  let head = Otoml.find_opt t Id.of_toml ["head"] in
  let leaders = Otoml.find_exn t (Otoml.get_array Id.of_toml) ["leaders"] in
  let followers = Otoml.find_exn t (Otoml.get_array Id.of_toml) ["followers"] in
  { head; leaders; followers; }

let couples_to_toml { couples; head; } =
  Otoml.inline_table (
    ("couples", Otoml.array (List.map Id.to_toml couples)) ::
    (match head with
     | None -> []
     | Some id -> ["head", Id.to_toml id])
  )

let couples_of_toml t =
  let head = Otoml.find_opt t Id.of_toml ["head"] in
  let couples = Otoml.find_exn t (Otoml.get_array Id.of_toml) ["couples"] in
  { head; couples; }

let panel_to_toml = function
  | Singles singles ->
    Otoml.array [Otoml.string "Singles"; singles_to_toml singles]
  | Couples couples ->
    Otoml.array [Otoml.string "Couples"; couples_to_toml couples]

let panel_of_toml t =
  match Otoml.get_array Otoml.get_value t with
  | cstr :: payload ->
    begin match Otoml.get_string cstr, payload with
      | "Singles", [singles] -> Singles (singles_of_toml singles)
      | "Couples", [couples] -> Couples (couples_of_toml couples)
      | s, _ -> raise (Otoml.Type_error ("Not a valid judge panel for constructor : " ^ s))
    end
  | _ -> raise (Otoml.Type_error ("Not a valid judge panel"))


(* DB interaction *)
(* ************************************************************************* *)

let () =
  State.add_init ~name:"judge" (fun st ->
      State.exec ~st {|
        CREATE TABLE IF NOT EXISTS judges (
          judge_id INTEGER REFERENCES dancers(id),
          phase_id INTEGER REFERENCES phases(id),
          judging INTEGER REFERENCES judging_names(id),

          PRIMARY KEY(judge_id, phase_id)
        )
      |})

let parse l =
  let rec singles acc = function
    | [] -> Singles acc
    | (judge_id, Judging.Leaders) :: r ->
      singles { acc with leaders = judge_id :: acc.leaders; } r
    | (judge_id, Judging.Followers) :: r ->
      singles { acc with followers = judge_id :: acc.followers; } r
    | (judge_id, Head) :: r ->
      begin match acc.head with
        | None -> singles { acc with head = Some judge_id; } r
        | Some _ -> failwith "multiple head judges"
      end
    | (_judge_id, Judging.Couples) :: _ ->
      failwith "mismatched judging for phase"
  in
  let rec couples acc = function
    | [] -> Couples acc
    | (judge_id, Judging.Couples) :: r ->
      couples { acc with couples = judge_id :: acc.couples; } r
    | (judge_id, Head) :: r ->
      begin match acc.head with
        | None -> couples { acc with head = Some judge_id; } r
        | Some _ -> failwith "multiple head judges"
      end
    | (_judge_id, Judging.Leaders) :: _
    | (_judge_id, Judging.Followers) :: _ ->
      failwith "mismatched judging for phase"
  in
  let rec aux l = function
    | [] -> failwith "not enough judging for phase"
    | (_, (Judging.Leaders | Judging.Followers)) :: _ ->
      singles { leaders = []; followers = []; head = None; } l
    | (_, Judging.Couples) :: _ ->
      couples { couples = []; head = None; } l
    | (_, Judging.Head) :: r -> aux l r
  in
  aux l l

let get ~st ~phase =
  let conv =
    Conv.mk Sqlite3_utils.Ty.[int; int]
      (fun judge_id judging -> (judge_id, Judging.of_int judging))
  in
  let l =
    State.query_list_where ~p:Id.p ~conv ~st
      {| SELECT judge_id, judging FROM judges WHERE phase_id = ? |}
      phase
  in
  parse l

let clear ~st ~phase =
  State.insert ~st ~ty:Id.p
    {| DELETE FROM judges WHERE phase_id = ? |} phase

let set_aux ~st ~phase ~judging judge_id =
  let judging = Judging.to_int judging in
  State.insert ~st ~ty:Sqlite3_utils.Ty.[int;int;int]
    {| INSERT INTO judges(judge_id,phase_id,judging)  VALUES (?,?,?) |}
    judge_id phase judging

let set ~st ~phase panel =
  let check_list judged = function
    | [] -> failwith ("empty list of judges for " ^ judged)
    | _ :: _ -> ()
  in
  match panel with
  | Singles { leaders; followers; head; } ->
    check_list "leaders" leaders;
    check_list "followers" followers;
    Logs.debug ~src:State.src (fun k->
        k "New panel: %a / %a"
          (Format.pp_print_list ~pp_sep:Format.pp_print_space Id.print) leaders
          (Format.pp_print_list ~pp_sep:Format.pp_print_space Id.print) followers
                              );
    clear ~st ~phase;
    List.iter (set_aux ~st ~phase ~judging:Leaders) leaders;
    List.iter (set_aux ~st ~phase ~judging:Followers) followers;
    Option.iter (set_aux ~st ~phase ~judging:Head) head
  | Couples { couples; head; } ->
    check_list "couples" couples;
    clear ~st ~phase;
    List.iter (set_aux ~st ~phase ~judging:Couples) couples;
    Option.iter (set_aux ~st ~phase ~judging:Head) head
