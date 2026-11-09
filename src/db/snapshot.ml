
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw.snapshot"

(* Snapshots *)
(* ************************************************************************* *)

(* TODO: also need to import the "results" table in order for promotion
   computation to work correctly (and the table that depends on it). *)

let make ~origin_db_path ~target_db_path =
  let st =
    State.mk
      ~init:false
      ~main_path:origin_db_path
      ~user_path:":memory:"
  in
  let st' =
    State.mk
      ~init:true
      ~main_path:target_db_path
      ~user_path:":memory:"
  in
  Dancer.iter ~st ~f:(fun dancer ->
      Dancer.Private.import ~st:st' ()
        ~id:(Lib.Dancer.id dancer)
        ~first_name:(Lib.Dancer.first_name dancer)
        ~last_name:(Lib.Dancer.last_name dancer)
        ?birthday:(Lib.Dancer.birthday dancer)
        ?email:(Lib.Dancer.email dancer)
        ~as_leader:(Lib.Dancer.as_leader dancer)
        ~as_follower:(Lib.Dancer.as_follower dancer)
    );
  ()
