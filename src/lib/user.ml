
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw.users"

(* Users *)
(* ************************************************************************* *)

type id = Id.t

type hash = string

type t = {
  (* id *)
  id : Id.t;

  (* core info *)
  name : string;
  email : string;

  (* link to FTW main db*)
  dancer_id : Id.t;
}

(* Passwd hash *)
(* ************************************************************************* *)

let verify_passwd ~encoded ~pwd =
  Argon2.verify ~encoded ~pwd ~kind:D 

let encode_passwd (pwd : string) =
  let hash_len = 32 in
  let t_cost = 2 in
  let m_cost = 65536 in
  let parallelism = 1 in
  let salt = "0000000000000000" in (* TODO: proper random salt *)
  let salt_len = String.length salt in
  let encoded_len =
    Argon2.encoded_len ~t_cost ~m_cost ~parallelism ~salt_len ~hash_len ~kind:D
  in
  match Argon2.hash ~pwd ~salt
          ~t_cost ~m_cost ~parallelism
          ~kind:D ~hash_len ~encoded_len
          ~version:VERSION_NUMBER with
  | Ok (_hash, encoded) -> Ok encoded
  | Error errcode ->
    let msg = Argon2.ErrorCodes.message errcode in
    Error msg


(* DB interaction *)
(* ************************************************************************* *)

let db = State.Users

let () =
  State.add_init ~name:"users" (fun st ->
    State.exec ~st ~db {|
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY,
        name TEXT UNIQUE,
        email TEXT,
        dancer_id INTEGER UNIQUE
      )
    |})

let () =
    State.add_init ~name:"passwd" (fun st ->
      State.exec ~st ~db {|
        CREATE TABLE IF NOT EXISTS passwd (
          id INTEGER PRIMARY KEY REFERENCES users(id),
          passwd TEXT,
          last_set TEXT
        )
      |})

let conv =
  Conv.mk Db.Ty.[int; text; text; int]
  (fun id name email dancer_id ->
    { id; name; email; dancer_id; })

let passwd ~st user_id =
  try
    Some (State.query_one_where ~st ~db ~p:Id.p ~conv:Conv.string
      {| SELECT passwd FROM passwd WHERE id = ? |} user_id)
  with Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND ->
    None

let find ~st = function
  | `Id id ->
    begin try
      Some (State.query_one_where ~st ~db ~p:Id.p ~conv
              {| SELECT * FROM users WHERE id = ? |} id)
    with Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND ->
      None
    end
  | `Name name ->
    begin try
      Some (State.query_one_where ~st ~db ~p:Db.Ty.[text] ~conv
              {| SELECT * FROM users WHERE name = ? |} name)
    with Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND ->
      None
    end
  | `Dancer dancer_id ->
    begin try
      Some (State.query_one_where ~st ~db ~p:Id.p ~conv
              {| SELECT * FROM users WHERE dancer_id = ? |} dancer_id)
    with Sqlite3_utils.RcError Sqlite3_utils.Rc.NOTFOUND ->
      None
    end

let authentificate ~st ~username ~pwd =
  match find ~st (`Name username) with
  | None -> `User_not_found
  | Some user ->
    match passwd ~st user.id with
    | None -> `Passwd_not_set
    | Some encoded ->
      match verify_passwd ~encoded ~pwd with
      | Ok true -> `All_good
      | Ok false -> `Bad_passwd
      | Error errcode -> `Hash_error (Argon2.ErrorCodes.message errcode)

let create ~st ~username ~email ~pwd ~dancer_id =
  match encode_passwd pwd with
  | Error _ ->
    assert false
  | Ok encoded_pwd ->
    State.atomically ~st ~f:(fun st ->
    State.insert ~st ~db ~ty:Db.Ty.[text; text; int]
      {| INSERT INTO users (name, email, dancer_id) VALUES (?,?,?) |}
      username email dancer_id;
    let user_id =
      State.query_one_where ~st ~db ~p:Id.p ~conv:Id.conv
        {| SELECT id FROM users WHERE dancer_id = ? |} dancer_id
    in
    State.insert ~st ~db ~ty:Db.Ty.[int; text]
      {| INSERT INTO passwd (id, passwd, last_set) VALUES (?,?,datetime('now','localtime')) |}
      user_id encoded_pwd
    )
