
type t =
  | Single of int
  | Couple of int * int

let to_string = function
  | Single d -> string_of_int d
  | Couple (l, f) -> Format.asprintf "%d-%d" l f

let of_string s =
  match int_of_string s with
  | res -> Single res
  | exception Failure _ ->
    begin match String.split_on_char '-' s with
      | [l; f] ->
        Couple (int_of_string l, int_of_string f)
      | _ -> failwith "bad encoded target"
    end

let conv =
  Conv.mk Sqlite3_utils.Ty.[text] of_string


