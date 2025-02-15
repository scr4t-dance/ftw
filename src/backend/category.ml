
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open Utils.Syntax

(* Routes *)
(* ************************************************************************* *)

let rec routes router =
  router
  |> Router.get "/api/categories" category_list
    ~tags:["category"]
    ~summary:"List existing categories"


(* Competition query *)
(* ************************************************************************* *)

and category_list =
  Api.get
    ~to_yojson:Types.CategoryList.to_yojson
    (fun _req _st ->
      let categories = Types.Category.schema.enum in
      let res : Types.CategoryList.t = { categories; } in
      Ok res
    )



