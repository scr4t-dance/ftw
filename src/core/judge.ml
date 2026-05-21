
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