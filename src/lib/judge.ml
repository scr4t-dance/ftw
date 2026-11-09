
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t

type singles = {
  leaders : Dancer.id list;
  followers : Dancer.id list;
  head : Dancer.id option;
}

type couples = {
  couples : Dancer.id list;
  head : Dancer.id option;
}

type panel =
  | Singles of singles
  | Couples of couples

let print_head fmt = function
  | None -> ()
  | Some judge -> Format.fprintf fmt "[%a] " Id.print judge

let print_list fmt l =
  let pp_sep fmt () = Format.fprintf fmt ", " in
  Format.pp_print_list ~pp_sep Id.print fmt l

let print fmt = function
  | Singles { head; leaders; followers; } ->
    Format.fprintf fmt "%a%a / %a"
      print_head head print_list leaders print_list followers
  | Couples { head; couples; } ->
    Format.fprintf fmt "%a%a"
      print_head head print_list couples

let judging panel dancer =
  let id = Dancer.id dancer in
  match panel with
  | Singles { head; leaders; followers; } ->
    if Option.equal Id.equal head (Some id) then Some (Judging.Head { targets = `Singles })
    else if List.exists (Id.equal id) leaders then Some Judging.Leaders
    else if List.exists (Id.equal id) followers then Some Judging.Followers
    else None (* TODO : mock judges *)
  | Couples { head; couples; } ->
    if Option.equal Id.equal head (Some id) then Some (Judging.Head { targets = `Couples })
    else if List.exists (Id.equal id) couples then Some Judging.Couples
    else None
