
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Competition result *)
(* ************************************************************************* *)

type aux =
  | Not_present           (* or unknown *)
  | Present               (* but rank unknown *)
  | Ranked of Rank.t list (* actual ranks, the list should be non-empty *)

type t = {
  prelims :       aux;
  octofinals :    aux;
  quarterfinals : aux;
  semifinals :    aux;
  finals :        aux;
}

type r = {
  competition : Competition.id;
  dancer : Dancer.id;
  role : Role.t;
  points : Points.t;
  result : t;
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
  | Ranked [] -> assert false (* internal assumption *)
  | Ranked (rank :: other_ranks) ->
    let r = List.fold_left Rank.min rank other_ranks in
    Finals (Some r)
  | Not_present ->
    begin match t.semifinals with
      | Present | Ranked _ -> Semifinals
      | Not_present -> Other
    end

(* Misc *)
(* ************************************************************************* *)

let merge_aux r r' =
  match r, r' with
  | Not_present, r''
  | r'', Not_present
  | Present, (Present as r'')
  | Present, ((Ranked _) as r'')
  | ((Ranked _) as r''), Present -> r''
  | Ranked l, Ranked l' -> Ranked (l @ l')

let merge r r' = {
  prelims = merge_aux r.prelims r'.prelims;
  octofinals = merge_aux r.octofinals r'.octofinals;
  quarterfinals = merge_aux r.quarterfinals r'.quarterfinals;
  semifinals = merge_aux r.semifinals r'.semifinals;
  finals = merge_aux r.finals r'.finals;
  }


