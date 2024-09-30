
exception Generic_error of string
exception Expected_an_int of string
exception Error_in_form of (string * string) list Dream.form_result
exception Error_in_multipart of Dream.multipart_form Dream.form_result

let int_param req id =
  let s = Dream.param req id in
  match int_of_string s with
  | i -> i
  | exception Failure _ ->
    raise (Expected_an_int s)

let int_query req id =
  match Dream.query req id with
  | Some s ->
    begin match int_of_string s with
      | i -> i
      | exception Failure _ ->
        raise (Expected_an_int s)
    end
  | None -> raise (Expected_an_int "")

let for_print req =
  match Dream.query req "print" with
  | Some "true" -> true
  | _ -> false
