
type 'a t =
  | Conv : ('b, 'a) Sqlite3_utils.Ty.t * 'b -> 'a t

let mk p res = Conv (p, res)

let (@>>) = Sqlite3_utils.Ty.(@>>)

let int = mk Sqlite3_utils.Ty.([int]) (fun i -> i)


