
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Results


(* TOML serialization *)
(* ************************************************************************* *)

let to_toml t =
  (* duplicate a bit the functions from `Rank`, but we really want to ensure
     that we can safely use `0` and that won't be confused with a rank *)
  let rank_to_toml r = Otoml.integer (Rank.rank r) in
  let aux name t' acc =
    match t' with
    | Not_present -> acc
    | Present -> (name, Otoml.integer 0) :: acc
    | Ranked [r] -> (name, rank_to_toml r) :: acc
    | Ranked l -> (name, Otoml.array (List.map rank_to_toml l)) :: acc
  in
  []
  |> aux "prelims" t.prelims
  |> aux "octofinals" t.octofinals
  |> aux "quarterfinals" t.quarterfinals
  |> aux "semifinals" t.semifinals
  |> aux "finals" t.finals
  |> Otoml.inline_table

let of_toml t =
  let aux_of_toml t =
    match Otoml.get_opt Otoml.get_integer t with
    | Some 0 -> Present
    | Some i -> Ranked [Rank.mk i]
    | None ->
      match Otoml.get_opt (Otoml.get_array Otoml.get_integer) t with
      | Some l -> Ranked (List.map Rank.mk l)
      | None -> raise (Otoml.Type_error "not the result of a phase")
  in
  let aux t name =
    match Otoml.find_opt t aux_of_toml [name] with
    | None -> Not_present
    | Some ret -> ret
  in
  {
    prelims = aux t "prelims";
    octofinals = aux t "octofinals";
    quarterfinals = aux t "quarterfinals";
    semifinals = aux t "semifinals";
    finals = aux t "finals";
  }


(* Int conversion *)
(* ************************************************************************* *)

let aux_to_int t =
  let rec aux = function
    | [] -> 0
    | rank :: l ->
      let i = Rank.rank rank in
      assert (1 <= i && i <= 254);
      let j = aux l in
      (* check that we do not overflow the integer *)
      assert (j land 0x7fff000000000000 = 0);
      i + (j lsl 8)
  in
  match t with
  | Not_present -> 0
  | Present -> 255
  | Ranked l -> aux l

let aux_of_int i =
  let rec aux i =
    if i = 0 then []
    else begin
      let r = Rank.mk (i land 0xff) in
      let i' = i lsr 8 in
      r :: aux i'
    end
  in
  match i with
  | 0 -> Not_present
  | 255 -> Present
  | _ -> Ranked (aux i)


(* DB interaction *)
(* ************************************************************************* *)

let db = State.Main

let () =
  State.add_init ~name:"results" (fun st ->
      State.exec ~st ~db {|
        CREATE TABLE IF NOT EXISTS results (
          competition INTEGER REFERENCES competitions(id),
          dancer INTEGER REFERENCES dancers(id),
          role INTEGER,
          points INTEGER,
          prelims INTEGER,
          octofinals INTEGER,
          quarterfinals INTEGER,
          semifinals INTEGER,
          finals INTEGER,
          PRIMARY KEY (competition, dancer, role)
        )
      |})

let conv =
  Conv.mk Db.Ty.[int; int; int; int; int; int; int; int; int]
    (fun competition dancer role points prelims octo quarter semi finals ->
       let role = Role.of_int role in
       let result = {
         prelims = aux_of_int prelims;
         octofinals = aux_of_int octo;
         quarterfinals = aux_of_int quarter;
         semifinals = aux_of_int semi;
         finals = aux_of_int finals;
       }
       in
       { competition; dancer; role; result; points; })

let add ~st ~competition ~dancer ~role ~result ~points =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~db ~ty:[int; int; int; int; int; int; int; int; int]
    {| INSERT INTO results
        (competition,dancer,role,points,prelims,octofinals,quarterfinals,semifinals,finals)
        VALUES (?,?,?,?,?,?,?,?,?) |}
    competition dancer (Role.to_int role) points
    (aux_to_int result.prelims)
    (aux_to_int result.octofinals)
    (aux_to_int result.quarterfinals)
    (aux_to_int result.semifinals)
    (aux_to_int result.finals)

let find ~st = function
  | `Competition competition ->
    State.query_list_where ~st ~db ~p:Id.p ~conv
      {| SELECT * FROM results WHERE competition = ? |} competition
  | `Dancer dancer ->
    State.query_list_where ~st ~db ~p:Id.p ~conv
      {| SELECT * FROM results WHERE dancer = ? |} dancer

let all_points ~st ~dancer ~role ~div =
  let open Db.Ty in
  let conv = Conv.mk [nullable int] CCFun.id in
  CCOption.get_or ~default:0 @@
  State.query_one_where ~st ~db ~conv ~p:[int; int; int]
    {| SELECT SUM(results.points)
       FROM results JOIN competitions ON results.competition=competitions.id
       WHERE results.dancer = ? AND results.role = ? AND competitions.category = ? |}
    dancer
    (Role.to_int role)
    (Category.to_int (Competitive div))

let promotion ~st ~event ~comp result =
  let role = result.role in
  let dancer = Dancer.get ~st result.dancer in
  let dancer_id = Dancer.id dancer in
  let current_points : Promotion.lazy_points = {
    novice = lazy (all_points ~st ~dancer:dancer_id ~role ~div:Novice);
    inter = lazy (all_points ~st ~dancer:dancer_id ~role ~div:Intermediate);
    adv = lazy (all_points ~st ~dancer:dancer_id ~role ~div:Advanced);
  } in
  Promotion.compute ~event ~comp ~dancer ~current_points ~result

