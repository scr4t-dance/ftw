
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include Lib.Permission

type Lib.Error.descr +=
  | Forbidden of {
      user : User.t option;
      perm : t;
    }

let check ~st ?user perm =
  Db.Permission.check ~st:(State.db st) ?user perm

let ensure ~st ?user perm =
  if check ~st ?user perm then Ok ()
  else Error (Lib.Error.mk (Forbidden { user; perm; }))

