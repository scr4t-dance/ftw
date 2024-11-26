
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Instantiate the Openapi_router module and Interface *)
(* ************************************************************************* *)

module Config = struct
  type app = default_routes:Dream.route list -> Dream.handler
  type route = Dream.route
  type handler = Dream.handler

  let doc_path = "/docs"
  let json_path = "/openapi.json"

  let doc_route html = Dream.get doc_path (fun _ -> Dream.html html)
  let json_route json = Dream.get json_path (fun _ -> Dream.json json)

  let get = Dream.get
  let post = Dream.post
  let delete = Dream.delete
  let put = Dream.put
  let options = Dream.options
  let head = Dream.head
  let patch = Dream.patch

  let build_routes main_routes ~default_routes =
    Dream.router (main_routes @ default_routes)
end

module T = Openapi_router.Make (Config)

(* Include the resulting module for more ease of use. *)
include T

