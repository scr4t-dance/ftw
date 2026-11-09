
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Artefact descriptions *)
(* ************************************************************************* *)

module Descr = struct

  type yan_criterions = {
    criterions : string list;
  }

  type t =
    | Ranking
    | Yans of yan_criterions

  let print fmt = function
    | Ranking ->
      Format.fprintf fmt "Ranking"
    | Yans { criterions } ->
      let pp_sep fmt () = Format.fprintf fmt ";@ " in
      Format.fprintf fmt "Yans(@[<hov>%a@])"
        (Format.pp_print_list ~pp_sep Format.pp_print_string) criterions

  let ranking () = Ranking
  let yans criterions = Yans criterions
  let mk_criterions criterions = { criterions; }


  (* jsont *)

  let yan_criterions_jsont =
    let criterions t = t.criterions in
    Jsont.Object.map ~kind:"YansCriterions" mk_criterions
    |> Jsont.Object.mem "criterions" (Jsont.list Jsont.string) ~enc:criterions
    |> Jsont.Object.finish

  let jsont =
    let unit_jsont =
      Jsont.Object.map ~kind:"RPSSConf" ()
      |> Jsont.Object.finish
    in
    let ranking = Jsont.Object.Case.map "Ranking" unit_jsont ~dec:ranking in
    let yans = Jsont.Object.Case.map "Yans" yan_criterions_jsont ~dec:yans in
    let enc_case = function
      | Ranking -> Jsont.Object.Case.value ranking ()
      | Yans conf -> Jsont.Object.Case.value yans conf
    in
    let cases = Jsont.Object.Case.[make ranking; make yans] in
    Jsont.Object.map ~kind:"ArtefactDescr" Fun.id
    |> Jsont.Object.case_mem "descr" Jsont.string ~enc:Fun.id ~enc_case cases
    |> Jsont.Object.finish

end

(* Artefact values *)
(* ************************************************************************* *)

type yan =
  | Yes
  | Alt
  | No (**)
(* Yes/Alt/No *)

type t =
  | Rank of Rank.t
  | Yans of yan list

let print fmt = function
  | Rank r -> Rank.print fmt r
  | Yans l ->
    let pp_sep fmt () = Format.fprintf fmt "/" in
    let pp fmt = function
      | Yes -> Format.fprintf fmt "Y"
      | Alt -> Format.fprintf fmt "A"
      | No -> Format.fprintf fmt "N"
    in
    Format.pp_print_list ~pp_sep pp fmt l

let printbox = function
  | Rank r ->
    PrintBox.hpad 1 @@ PrintBox.asprintf "%a" Rank.print r
  | Yans l ->
    let aux = function
      | Yes -> PrintBox.asprintf "3"
      | Alt -> PrintBox.asprintf "2"
      | No -> PrintBox.asprintf "1"
    in
    PrintBox.hlist ~bars:true ~pad:(PrintBox.hpad 3) (List.map aux l)

let check ~descr t =
  match descr, t with
  | Descr.Ranking, Rank _ -> true
  | Descr.Yans { criterions; }, Yans l -> List.length criterions = List.length l
  | _ -> false

