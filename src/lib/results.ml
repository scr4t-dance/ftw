
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

include Ftw_core.Results


(* TOML serialization *)
(* ************************************************************************* *)

let p_to_toml p =
  Otoml.inline_table [
    "dancer", Id.to_toml p.dancer;
    "points", Points.to_toml p.points;
  ]

let p_of_toml toml =
  {
    dancer = Otoml.find_exn toml Id.of_toml ["dancer"];
    points = Otoml.find_exn toml Points.of_toml ["points"];
  }

let to_toml t =
  (* duplicate a bit the functions from `Rank`, but we really want to ensure
     that we can safely use `0` and that won't be confused with a rank *)
  let rank_to_toml r = Otoml.integer (Rank.rank r) in
  let aux name t' acc =
    match t' with
    | Not_present -> acc
    | Present -> (name, Otoml.integer 0) :: acc
    | Ranked r -> (name, rank_to_toml r) :: acc
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
    | Some i -> Ranked (Rank.mk i)
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
  match t with
  | Not_present -> 0
  | Present -> 255
  | Ranked r ->
    let r = Rank.rank r in
    assert (0 < r && r < 255);
    r

let aux_of_int i =
  match i with
  | 0 -> Not_present
  | 255 -> Present
  | r -> Ranked (Rank.mk r)


(* DB interaction *)
(* ************************************************************************* *)

let db = State.Main

let () =
  State.add_init ~name:"results" (fun st ->
      State.exec ~st ~db {|
        CREATE TABLE IF NOT EXISTS results (
          competition INTEGER REFERENCES competitions(id),
          prelims INTEGER,
          octofinals INTEGER,
          quarterfinals INTEGER,
          semifinals INTEGER,
          finals INTEGER,
          dancer1 INTEGER,
          points1 INTEGER,
          dancer2 INTEGER,
          points2 INTEGER,
          dancer3 INTEGER,
          points3 INTEGER
        )
      |})

let conv =
  Conv.mk Db.Ty.[int; int; int; int; int; int; int; int; int; int; int; int]
    (fun competition prelims octo quarter semi finals d1 p1 d2 p2 d3 p3 ->
      let target =
        match d1, d2, d3 with
        | 0, 0, 0 -> assert false
        | _, 0, 0 ->
          let target : p = { dancer = d1; points = p1; } in
          Target.(Any (Single { target; role = Leader; }))
        | 0, _, 0 ->
          let target : p = { dancer = d2; points = p2; } in
          Target.(Any (Single { target; role = Follower; }))
        | _, _, 0 ->
          let leader : p = { dancer = d1; points = p1; } in
          let follower : p = { dancer = d2; points = p2; } in
          Target.(Any (Couple { leader; follower }))
        | _, _, _ ->
          let target1 : p = { dancer = d1; points = p1; } in
          let target2 : p = { dancer = d2; points = p2; } in
          let target3 : p = { dancer = d3; points = p3; } in
          Target.Any (Trouple {target1; target2; target3; })
      in
       let result = {
         prelims = aux_of_int prelims;
         octofinals = aux_of_int octo;
         quarterfinals = aux_of_int quarter;
         semifinals = aux_of_int semi;
         finals = aux_of_int finals;
       }
       in
       { competition; target; result; })

let add ~st { competition; target; result; }  =
  let d1, p1, d2, p2, d3, p3 =
    match target with
    | Any Single { target = { dancer; points; }; role = Leader; } ->
      dancer, points, 0, 0, 0, 0
    | Any Single { target = { dancer; points; }; role = Follower; } ->
      0, 0, dancer, points, 0, 0
    | Any Couple { leader = { dancer = d1; points = p1}; follower = { dancer = d2; points = p2 } } ->
      d1, p1, d2, p2, 0, 0
    | Any Trouple { target1 = { dancer = d1; points = p1; };
                    target2 = { dancer = d2; points = p2; };
                    target3 = { dancer = d3; points = p3; }} ->
      d1, p1, d2, p2, d3, p3
  in
  State.insert ~st ~db ~ty:Db.Ty.[int; int; int; int; int; int; int; int; int; int; int; int]
    {| INSERT INTO results
        (competition,prelims,octofinals,quarterfinals,semifinals,finals,dancer1,points1,dancer2,points2,dancer3,points3)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?) |}
    competition
    (aux_to_int result.prelims)
    (aux_to_int result.octofinals)
    (aux_to_int result.quarterfinals)
    (aux_to_int result.semifinals)
    (aux_to_int result.finals)
    d1 p1 d2 p2 d3 p3

let find ~st = function
  | `Competition competition ->
    State.query_list_where ~st ~db ~p:Id.p ~conv
      {| SELECT * FROM results WHERE competition = ? |}
      (Competition.id competition)
  | `Dancer dancer ->
    State.query_list_where ~st ~db ~p:Id.p ~conv
      {| SELECT * FROM results WHERE dancer = ? |}
      (Dancer.id dancer)

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
  let get_dancer id = Dancer.get ~st id in
  let current_points dancer_id role : Promotion.lazy_points = {
    novice = lazy (all_points ~st ~dancer:dancer_id ~role ~div:Novice);
    inter = lazy (all_points ~st ~dancer:dancer_id ~role ~div:Intermediate);
    adv = lazy (all_points ~st ~dancer:dancer_id ~role ~div:Advanced);
  } in
  Promotion.compute ~get_dancer ~event ~comp ~current_points ~result

