
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw.snapshot"

(* Snapshots *)
(* ************************************************************************* *)

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
        ~id:(Dancer.id dancer)
        ~first_name:(Dancer.first_name dancer)
        ~last_name:(Dancer.last_name dancer)
        ?birthday:(Dancer.birthday dancer)
        ?email:(Dancer.email dancer)
        ~as_leader:(Dancer.as_leader dancer)
        ~as_follower:(Dancer.as_follower dancer)
    );
  ()
