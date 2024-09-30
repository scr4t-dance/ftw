
(* ************************************************************************ *)
(* Final ranking export *)
(* ************************************************************************ *)

type rank =
  | Ranked of int
  | Semi_finals

let pp_rank fmt = function
  | Ranked i -> Format.fprintf fmt "%d" i
  | Semi_finals -> Format.fprintf fmt "S"

let tsv_line fmt (rank, role, dancer) =
  Format.fprintf fmt "%a\t%s\t%s\t%s@."
    pp_rank rank (Role.short role)
    (Dancer.last_name dancer) (Dancer.first_name dancer)

let finals_to_tsv st couples =
  let buf = Buffer.create 1013 in
  let fmt = Format.formatter_of_buffer buf in
  let aux fmt rank role dancer_id =
    let dancer = Dancer.find_bib st dancer_id in
    tsv_line fmt (Ranked (rank + 1), role, dancer)
  in
  Array.iteri (fun r couple ->
      aux fmt r Leader couple.Rank.Couple.leader;
      aux fmt r Follower couple.Rank.Couple.follow
    ) couples;
  Buffer.contents buf

let semis_to_tsv st leaders follows =
  let buf = Buffer.create 1013 in
  let fmt = Format.formatter_of_buffer buf in
  let aux role =
    Array.iter (fun bib ->
        let dancer = Dancer.find_bib st bib in
        tsv_line fmt (Semi_finals, role, dancer)
      )
  in
  aux Leader leaders;
  aux Follower follows;
  Buffer.contents buf

