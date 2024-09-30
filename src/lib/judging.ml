
type t =
  | Head
  | Leader
  | Follow
  | Bonus

let to_int = function
  | Head -> 0
  | Leader -> 1
  | Follow -> 2
  | Bonus -> 3

let of_int = function
  | 0 -> Head
  | 1 -> Leader
  | 2 -> Follow
  | 3 -> Bonus
  | _ -> failwith "incorrect judging"

let conv =
  Conv.mk Sqlite3_utils.Ty.[int] of_int

let to_string = function
  | Head -> "Head Judge"
  | Leader -> "Leaders"
  | Follow -> "Followers"
  | Bonus -> "Bonus"

let () =
  State.add_init (fun st ->
      Sqlite3_utils.exec0_exn st {|
        CREATE TABLE IF NOT EXISTS judging (
          phase INTEGER,
          judge INTEGER,
          judging INTEGER,
        CONSTRAINT unicity
          UNIQUE (phase, judge)
          ON CONFLICT REPLACE
        )
      |})

let judges st ~phase =
  State.query_list_where ~st ~conv:Id.conv ~p:Id.p
    {|SELECT judge FROM judging WHERE phase = ?|} phase

let get st ~phase ~judge =
  try
    let open Sqlite3_utils.Ty in
    Some (State.query_one_where ~st ~conv ~p:[int; int]
      {|SELECT judging FROM judging WHERE phase = ? AND judge = ?|} phase judge)
  with Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND -> None

let set st ~phase ~judge = function
  | None ->
    let open Sqlite3_utils.Ty in
    State.insert ~st ~ty:[int; int]
      {|DELETE FROM judging WHERE phase = ? AND judge = ? |}
      phase judge
  | Some t ->
    let open Sqlite3_utils.Ty in
    State.insert ~st ~ty:[int; int; int]
      {|INSERT INTO judging(phase, judge, judging) VALUES (?,?,?)|}
      phase judge (to_int t)

let split_judges st ~phase l =
  List.fold_left (fun (head, leaders, follows) judge ->
      match get st ~phase ~judge with
      | None -> (head, leaders, follows)
      | Some Head -> (Some judge, leaders, follows)
      | Some Bonus -> (Some judge, leaders, follows)
      | Some Leader -> (head, judge :: leaders, follows)
      | Some Follow -> (head, leaders, judge :: follows)
    ) (None, [], []) l

