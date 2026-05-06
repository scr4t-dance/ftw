
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Ftw_core import *)
(* ************************************************************************* *)

type t =
  | Admin
  | Director of { ev : Event.id; }
  | Scorer of { ev: Event.id; }
  | Clerk of { ev : Event.id; }
  | Emcee of { ev : Event.id; comp: Competition.id; }
  | Head_Judge of { ev : Event.id; comp : Competition.id; }
  | Judge of { ev: Event.id; comp : Competition.id; phase: Phase.id; }
  | Mock_Judge of { ev: Event.id; comp : Competition.id; phase: Phase.id; }
  | Marshaller of { ev: Event.id; comp : Competition.id; phase: Phase.id; }

(* Creation and inspection *)
(* ************************************************************************* *)

let discr = function
  | Admin -> 0
  | Director _ -> 1
  | Scorer _ -> 2
  | Clerk _ -> 3
  | Emcee _ -> 4
  | Head_Judge _ -> 5
  | Judge _ -> 6
  | Mock_Judge _ -> 7
  | Marshaller _ -> 8

let ev = function
  | Admin -> 0
  | Director { ev; }
  | Scorer { ev; }
  | Clerk { ev; }
  | Emcee { ev; _ }
  | Head_Judge { ev; _ }
  | Judge { ev; _ }
  | Mock_Judge { ev; _ }
  | Marshaller { ev; _ } -> ev

let comp = function
  | Admin
  | Director _
  | Scorer _ 
  | Clerk _ -> 0
  | Emcee { comp; _ }
  | Head_Judge { comp; _ }
  | Judge { comp; _ }
  | Mock_Judge { comp; _ }
  | Marshaller { comp; _ } -> comp

let phase = function
  | Admin
  | Director _
  | Scorer _
  | Clerk _
  | Emcee _
  | Head_Judge _ -> 0
  | Judge { phase; _ }
  | Mock_Judge { phase; _ }
  | Marshaller { phase; _ } -> phase



(* Position sorting *)
(* ************************************************************************* *)



(* DB interaction *)
(* ************************************************************************* *)

let db = State.Users

let () =
  State.add_init ~name:"positions" (fun st ->
    State.exec ~st ~db {|
      CREATE TABLE IF NOT EXISTS positions (
        user_id INTEGER REFERENCES users(id),
        event_id INTEGER,
        comp_id INTEGER,
        phase_id INTEGER,
        position INTEGER)
  |})

let conv =
  Conv.mk Db.Ty.[int; int; int; int; int]
  (fun _user_id ev comp phase d ->
    match d with
    | 0 -> Admin
    | 1 -> Director { ev; }
    | 2 -> Scorer { ev; }
    | 3 -> Clerk { ev; }
    | 4 -> Emcee {ev; comp;}
    | 5 -> Head_Judge { ev; comp; }
    | 6 -> Judge { ev; comp; phase; }
    | 7 -> Judge { ev; comp; phase; }
    | 8 -> Marshaller { ev; comp; phase; }
    | _ -> assert false (* TODO: proper error *)
    )

let add ~st ~user pos =
  State.insert ~st ~db ~ty:Db.Ty.[int; int; int; int; int]
  {| INSERT INTO positions (user_id, event_id, comp_id, phase_id, position) VALUES (?,?,?,?,?) |}
  (User.id user) (ev pos) (comp pos) (phase pos) (discr pos)

let clear_from_event ~st ~user ~ev =
  State.insert ~st ~db ~ty:Db.Ty.[int; int]
  {| DELETE FROM positions WHERE user_id = ? AND event_id = ? |}
  (User.id user) (Event.id ev)

let get_global ~st ~user =
  State.query_list_where ~st ~db ~p:Id.p ~conv
  {| SELECT * FROM positions WHERE user_id = ? AND event_id = 0
                               AND comp_id = 0 AND phase_id = 0 |}
  (User.id user)

let get_all_for_event ~st ~user ~ev =
  match user with
  | None -> []
  | Some user ->
    State.query_list_where ~st ~db ~p:Db.Ty.[int; int] ~conv
      {| SELECT * FROM positions WHERE user_id = ? AND (event_id = ? OR event_id = 0) |}
      (User.id user) (Event.id ev)

