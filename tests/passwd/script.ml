
let () =
  let hash_len = 32 in
  let t_cost = 2 in
  let m_cost = 65536 in
  let parallelism = 1 in
  let salt = "0000000000000000" in
  let salt_len = String.length salt in
  let pwd = "password" in
  let encoded_len =
    Argon2.encoded_len ~t_cost ~m_cost ~parallelism ~salt_len ~hash_len ~kind:D
  in
  match Argon2.hash ~pwd ~salt
          ~t_cost ~m_cost ~parallelism
          ~kind:D ~hash_len ~encoded_len
          ~version:VERSION_NUMBER with
  | Ok (hash, encoded) ->
    Format.printf "hash : %s@\nencoded: %s@." hash encoded
  | Error errcode ->
    Format.eprintf "Error !@\n%s@." (Argon2.ErrorCodes.message errcode)


