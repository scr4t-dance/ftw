

let () =
  let secret = Dream.to_base64url (Dream.random 32) in
  Format.printf "%s@." secret

