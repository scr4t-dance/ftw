
type t =
  | Rank of int
  | Note of {
      technique : int;
      musicality : int;
      teamwork : int;
    }
  | Single_note of int

let to_string = function
  | Rank i -> string_of_int i
  | Single_note i -> Format.asprintf "%d-" i
  | Note { technique; musicality; teamwork; } ->
    Format.asprintf "%d-%d-%d" technique musicality teamwork

let of_string s =
  match int_of_string s with
  | res -> Rank res
  | exception Failure _ ->
    begin match String.split_on_char '-' s with
      | [note; _] ->
        Single_note (int_of_string note)
      | [technique; musicality; teamwork] ->
        Note {
          technique = int_of_string technique;
          musicality = int_of_string musicality;
          teamwork = int_of_string teamwork;
        }
      | _ -> failwith "bad encoded artefact"
    end

let () =
  State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS judgements (
          phase INTEGER,
          judge INTEGER,
          target TEXT,
          artefact TEXT,
        CONSTRAINT unicity
          UNIQUE (phase, judge, target)
          ON CONFLICT REPLACE
        )
      |})

let conv =
  Conv.mk Sqlite3_utils.Ty.[text] of_string

let get st ~phase ~judge ~target : t option =
  let open Sqlite3_utils.Ty in
  try
    Some (State.query_one_where ~st ~conv ~p:[int; int; text]
            {|SELECT artefact FROM judgements WHERE phase = ? AND judge = ? AND target = ?|}
            phase judge (Target.to_string target))
  with Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND -> None

let set st ~phase ~judge ~target = function
  | None ->
    let open Sqlite3_utils.Ty in
    State.insert ~st ~ty:[int; int; text]
      {|DELETE FROM judgements WHERE phase = ? AND judge = ? AND target = ?|}
      phase judge (Target.to_string target)
  | Some artefact ->
    let open Sqlite3_utils.Ty in
    State.insert ~st ~ty:[int; int; text; text]
      {|INSERT INTO judgements(phase,judge,target,artefact) VALUES (?,?,?,?)|}
      phase judge (Target.to_string target) (to_string artefact)

let list st ~phase ~judge =
  let open Sqlite3_utils.Ty in
  let conv =
    Conv.mk [text; text]
      (fun target artefact -> (Target.of_string target, of_string artefact))
  in
  State.query_list_where ~st ~conv ~p:[int; int]
    {|SELECT target, artefact FROM judgements WHERE phase = ? AND judge = ?|}
    phase judge

let targets st ~phase =
  State.query_list_where ~st ~conv:Target.conv ~p:Id.p
    {|SELECT target FROM judgements WHERE phase = ?|} phase

let find_follower st ~phase leader =
  let l = targets st ~phase in
  List.find_map (function
      | Target.Couple (l, f) when l = leader -> Some (f)
      | _ -> None
    ) l

