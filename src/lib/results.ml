
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Competition result *)
(* ************************************************************************* *)

type aux =
  | Not_present       (* or unknown *)
  | Present           (* but rank unknown *)
  | Ranked of Rank.t  (* actual rank *)

type t = {
  prelims :       aux;
  octofinals :    aux;
  quarterfinals : aux;
  semifinals :    aux;
  finals :        aux;
}

let mk
    ?(prelims=Not_present)
    ?(octofinals=Not_present)
    ?(quarterfinals=Not_present)
    ?(semifinals=Not_present)
    ?(finals=Not_present) () =
  { prelims; octofinals; quarterfinals; semifinals; finals; }

(* Some values *)

let finalist = mk () ~finals:Present
let semifinalist = mk () ~semifinals:Present
let quarterfinalist = mk () ~quarterfinals:Present
let octofinalist = mk () ~octofinals:Present

let placement (t : t) : Points.placement =
  match t.finals with
  | Present -> Finals None
  | Ranked rank -> Finals (Some rank)
  | Not_present ->
    begin match t.semifinals with
      | Present | Ranked _ -> Semifinals
      | Not_present -> Other
    end

(* Int conversion *)
(* ************************************************************************* *)

let to_int t =
  let aux n r =
    let i =
      match r with
      | Not_present -> 0
      | Present -> 255
      | Ranked r ->
        let i = Rank.rank r in
        (* we encode each rank using 1 byte *)
        assert (1 <= i && i <= 254); i
    in
    i lsl (n * 8)
  in
  aux 0 t.finals lor
  aux 1 t.semifinals lor
  aux 2 t.prelims lor
  aux 3 t.quarterfinals lor
  aux 4 t.octofinals

let of_int i =
  let[@inline] aux i n =
    let j = (i lsr (n * 8)) land 255 in
    match j with
    | 0 -> Not_present
    | 255 -> Present
    | _ -> Ranked (Rank.mk j)
  in
  {
    prelims = aux i 2;
    octofinals = aux i 4;
    quarterfinals = aux i 3;
    semifinals = aux i 1;
    finals = aux i 0;
  }

(* TOML serialization *)
(* ************************************************************************* *)

let to_toml t =
  let aux name t' acc =
    match t' with
    | Not_present -> acc
    | Present -> (name, Otoml.integer 0) :: acc
    | Ranked r -> (name, Rank.to_toml r) :: acc
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
    match Otoml.get_integer t with
    | 0 -> Present
    | _ -> Ranked (Rank.of_toml t)
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


(* DB interaction *)
(* ************************************************************************* *)

let () =
  State.add_init ~name:"results" (fun st ->
      State.exec ~st {|
        CREATE TABLE IF NOT EXISTS results (
          competition INTEGER REFERENCES competitions(id),
          dancer INTEGER REFERENCES dancers(id),
          role INTEGER,
          result INTEGER,
          points INTEGER,
          PRIMARY KEY (competition, dancer, role)
        )
      |})

type r = {
  competition : Competition.id;
  dancer : Dancer.id;
  role : Role.t;
  result : t;
  points : Points.t;
}

let conv =
  Conv.mk Sqlite3_utils.Ty.[int; int; int; int; int]
    (fun competition dancer role result points ->
       let role = Role.of_int role in
       let result = of_int result in
       { competition; dancer; role; result; points; })

let add ~st ~competition ~dancer ~role ~result ~points =
  let open Sqlite3_utils.Ty in
  State.insert ~st ~ty:[int; int; int; int; int]
    {| INSERT INTO results (competition,dancer,role,result,points) VALUES (?,?,?,?,?) |}
    competition dancer (Role.to_int role) (to_int result) points

let find ~st = function
  | `Competition competition ->
    State.query_list_where ~st ~p:Id.p ~conv
      {| SELECT * FROM results WHERE competition = ? |} competition
  | `Dancer dancer ->
    State.query_list_where ~st ~p:Id.p ~conv
      {| SELECT * FROM results WHERE dancer = ? |} dancer

let all_points ~st ~dancer ~role ~div =
  let open Sqlite3_utils.Ty in
  let conv = Conv.mk [nullable int] CCFun.id in
  CCOption.get_or ~default:0 @@
  State.query_one_where ~st ~conv ~p:[int; int; int]
    {| SELECT SUM(results.points)
       FROM results JOIN competitions ON results.competition=competitions.id
       WHERE results.dancer = ? AND results.role = ? AND competitions.category = ? |}
    dancer
    (Role.to_int role)
    (Category.to_int (Competitive div))

