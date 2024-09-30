
type t = {
  page : string;
  title : string;
  body : Dream.request -> Ftw.State.t -> string;
}

let mk ~page ~title ~body =
  { page; title; body; }

let render { page; title; body; } request =
  let print =
    match Dream.query request "print" with
    | Some "true" -> true
    | _ -> false
  in
  State.get request (fun st ->
      Dream.html @@
      Template.render ~print ~title ~page ~body:(body request st)
    )

let raw { page = _; title; body; } request =
  State.get request @@ fun st ->
  let headers = [
    "Content-Disposition",
      Format.asprintf {|attachment; filename="%s"|} title;
  ] in
  Dream.respond ~headers (body request st)

