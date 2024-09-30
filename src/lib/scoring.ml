
type t =
  | Strictly_Prelims
  | JJ_Prelims
  | Finals

let to_int = function
  | Finals -> 0
  | JJ_Prelims -> 1
  | Strictly_Prelims -> 2

let of_int = function
  | 0 -> Finals
  | 1 -> JJ_Prelims
  | 2 -> Strictly_Prelims
  | _ -> failwith "not a correct scoring"

let conv =
  Conv.mk Sqlite3_utils.Ty.[int] of_int

let to_string = function
  | Finals -> "Finals"
  | JJ_Prelims -> "J&J Prelims"
  | Strictly_Prelims -> "Strictly Prelims"

