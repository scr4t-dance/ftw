
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let src = Logs.Src.create "ftw.ranking"

(* Base types *)
(* ************************************************************************* *)

module Status = struct

  type t =
    | Complete
    | Partial
    | Impossible

  let print fmt = function
    | Complete -> ()
    | Partial -> Format.fprintf fmt "!! partial !!"
    | Impossible -> Format.fprintf fmt "?? cannot rank ??"

end

(* One ranking *)
(* ************************************************************************* *)

module One = struct

  type 'a ranked =
    | None
    | Ranked of {
        rank : Rank.t;
        target : 'a;
      }
    | Tie of {
        rank : Rank.t;
        tie : 'a array;
      }


  (** Array of Ranked *)
  type 'a t = {
    ranks : 'a ranked array;
  }

  type with_heat_ids = Id.t t

  let empty n =
    { ranks = Array.make n None; }

  let get { ranks; } r =
    let i = Rank.to_index r in
    match ranks.(i) with
    | None -> Option.None
    | Ranked { target; rank } -> Some (rank, target)
    | Tie { rank; tie; } -> Some (rank, tie.(i - Rank.to_index rank))

  let set { ranks; } i tie =
    if Array.length tie = 1 then
      ranks.(i) <- Ranked { rank = Rank.of_index i; target = tie.(0); }
    else begin
      for j = i to i + Array.length tie - 1 do
        ranks.(j) <- Tie { rank = Rank.of_index i; tie; }
      done
    end

  let map_targets ~f { ranks; } =
    let ranks =
      Array.map (function
          | None -> None
          | Ranked { rank; target; } ->
            Ranked { rank; target = f target; }
          | Tie { rank; tie; } ->
            Tie { rank; tie = Array.map f tie; }
        ) ranks
    in
    { ranks; }

  let printbox_matrix ~pp { ranks } =
    let n = Array.length ranks in
    let m = 2 in
    let matrix = Array.make_matrix n m PrintBox.empty in
    for line = 0 to n - 1 do
      for col = 0 to m - 1 do
        let contents =
          match col with
          | 0 ->
            begin match ranks.(line) with
              | Ranked _ -> PrintBox.int (line + 1)
              | Tie { rank; _ } when Rank.to_index rank = line -> PrintBox.int (line + 1)
              | Tie _ -> PrintBox.empty
              | None -> PrintBox.asprintf "n/a"
            end
          | 1 ->
            let target_id_opt : _ option =
              match ranks.(line) with
              | None -> None
              | Ranked { rank = _; target; } -> Some target
              | Tie { rank; tie; } -> Some (tie.(line - Rank.to_index rank))
            in
            begin match target_id_opt with
              | None -> PrintBox.empty
              | Some target -> PrintBox.asprintf "%a" pp target
            end
          | _ -> assert false
        in
        matrix.(line).(col) <- contents
      done
    done;
    matrix

  let print ~pp fmt t =
    let box = PrintBox.grid ~bars:true (printbox_matrix ~pp t) in
    PrintBox_text.pp fmt box

end


(* Artefact Matrix *)
(* *********************************************************************** *)

module Matrix = struct

  type ('acc, 'target) t = {
    (* info about judges *)
    head : bool;
    judges : 'target array;
    (* info about targets *)
    targets : 'target array;
    (* artefacts (and bonus) for each target/judge pair *)
    mutable missing_artefacts : int;
    artefacts : Artefact.t option array array;
    bonus : Bonus.t array;
    (* accumulator for ranking algorithms *)
    ranking_acc : 'acc array;
    (* resulting ranking *)
    ranks : 'target One.t;
  }

  (* accessors *)

  let ranks t = t.ranks

  let length t =
    Array.length t.artefacts

  let width t =
    Array.length t.artefacts.(0)

  let target t ~i =
    t.targets.(i)

  let judge t ~j =
    t.judges.(j)

  let bonus t ~i =
    t.bonus.(i)

  let head t =
    if t.head then Some 0 else None

  let is_head t ~j =
    j = 0 && t.head

  let missing_artefacts t = t.missing_artefacts

  let artefact t ~i ~j =
    match t.artefacts.(i).(j) with
    | None -> failwith "missing artefact"
    | Some artefact -> artefact

  (* debug printing *)

  let printbox_matrix ~acc_line ~acc_side ~pp t =
    let ranks = One.printbox_matrix ~pp t.ranks in
    let acc = Array.map acc_line t.ranking_acc in
    let targets = Array.map (fun target -> [| PrintBox.asprintf "%a" pp target |]) t.targets in
    let artefacts =
      Array.map (Array.map (function
          | None -> PrintBox.empty
          | Some artefact -> Artefact.printbox artefact
        )) t.artefacts
    in
    let blank = Array.make (Array.length artefacts) [|PrintBox.empty|] in
    match acc_side with
    | `Left -> Misc.Matrix.(ranks ++ blank ++ acc ++ blank ++ artefacts ++ blank ++ targets)
    | `Right -> Misc.Matrix.(ranks ++ blank ++ artefacts ++ blank ++ acc ++ blank ++ targets)

  let printbox ~acc_line ~acc_side ~pp t =
    let matrix = printbox_matrix ~acc_line ~acc_side ~pp t in
    PrintBox.grid matrix

  (* initialization *)

  let init ~head ~judges ~targets ~acc =
    let targets = Array.of_list targets in
    let judges =
      Array.of_list @@
      match head with
      | Some h -> h ::judges
      | None -> judges
    in
    let m = Array.length judges in
    let n = Array.length targets in
    let head = Option.is_some head in
    let bonus = Array.make n Bonus.zero in
    let artefacts = Array.make_matrix n m None in
    let missing_artefacts = n * m in
    let ranking_acc = Array.init n (fun _ -> acc n) in
    let ranks = One.empty n in
    let t = { head; judges; targets; artefacts; bonus; missing_artefacts; ranking_acc; ranks; } in
    Logs.debug ~src (fun k->k "matrix init: %d targets, %d judges" n m);
    t

  let map ~targets:f ~judges:g t =
    let judges = Array.map g t.judges in
    let targets = Array.map f t.targets in
    let ranks = One.map_targets ~f t.ranks in
    { t with targets; judges; ranks;  }

  (* filing up the matrix with artefacts *)

  let acc_bonus ~i ~bonus t =
    t.bonus.(i) <- bonus

  let acc_artefact ~i ~j ~artefact t =
    match t.artefacts.(i).(j) with
    | None ->
      t.missing_artefacts <- t.missing_artefacts - 1;
      t.artefacts.(i).(j) <- Some artefact
    | Some _ -> failwith "duplicate artefact"

  (* Ranking helpers *)

  let get ~i t =
    t.ranking_acc.(i)

  let set ~i t a =
    t.ranking_acc.(i) <- a

  let swap t i j =
    (* swap should only be called on "unranked" targets *)
    CCArray.swap t.bonus i j;
    CCArray.swap t.targets i j;
    CCArray.swap t.artefacts i j;
    CCArray.swap t.ranking_acc i j

  let rec sort ~cmp ~start ~stop t =
    (* for now we use bubble sort, as it is simpler,
       but any other sort algo would work *)
    let swapped = ref false in
    for i = start + 1 to stop do
      if cmp t.ranking_acc.(i - 1) t.ranking_acc.(i) > 0 then begin
        swap t (i - 1) i;
        swapped := true
      end
    done;
    if !swapped then sort ~cmp ~start ~stop t

  let rec segments ~cmp ~start ~stop ~f t =
    if start > stop then ()
    else begin
      let base = t.ranking_acc.(start) in
      let cursor = ref (start + 1) in
      while !cursor <= stop &&
            cmp base t.ranking_acc.(!cursor) = 0 do
        incr cursor
      done;
      f ~start ~stop:(!cursor - 1);
      segments ~cmp ~start:(!cursor) ~stop ~f t
    end

end

(* Algorithms - Yan wieghted *)
(* *********************************************************************** *)

module Yan_weighted = struct

  type weight = {
    yes : int;
    alt : int;
    no : int;
  } [@@deriving yojson]

  type conf = {
    weights : weight list;
    head_weights : weight list;
  } [@@deriving yojson]

  (* printing *)

  let print_weight fmt { yes; alt; no; } =
    Format.fprintf fmt "%d/%d/%d" yes alt no

  let print_weights fmt l =
    match Misc.Lists.all_the_same ~eq:(=) l with
    | Some t when List.length l > 1 ->
      Format.fprintf fmt "@@(%a)" print_weight t
    | _ ->
      let pp_sep fmt () = Format.fprintf fmt ",@ " in
      Format.pp_print_list ~pp_sep print_weight fmt l

  let print_conf fmt { weights; head_weights; } =
    Format.fprintf fmt "%a / %a"
      print_weights weights
      print_weights head_weights

  (* serialization *)

  let weight_to_toml { yes; alt; no; } =
    Otoml.inline_table [
      "yes", Otoml.integer yes;
      "alt", Otoml.integer alt;
      "no", Otoml.integer no;
    ]

  let weight_of_toml t =
    let yes = Otoml.find_exn t Otoml.get_integer ["yes"] in
    let alt = Otoml.find_exn t Otoml.get_integer ["alt"] in
    let no = Otoml.find_exn t Otoml.get_integer ["no"] in
    { yes; alt; no; }

  let weights_to_toml l =
    Otoml.array (List.map weight_to_toml l)

  let weights_of_toml t =
    Otoml.get_array weight_of_toml t

  let conf_to_toml { weights; head_weights; } =
    [ weights_to_toml weights;
      weights_to_toml head_weights ]

  let conf_of_toml = function
    | [ w; h_w ] ->
      let weights = weights_of_toml w in
      let head_weights = weights_of_toml h_w in
      { weights; head_weights; }
    | _ ->
      assert false (* TODO: error msg *)


  (* creating and computing the ranking accumulator *)

  type acc = {
    judges : int;
    head : int;
    bonus : Bonus.t;
  }

  let acc_line { judges; head; bonus; } =
    [| PrintBox.asprintf "%d / %d%s"
         judges head
         (if bonus = 0 then "" else Format.asprintf ".%d" bonus) |]

  let acc _n = { judges = 0; head = 0; bonus = 0; }

  let extract artefact =
    match (artefact : Artefact.t) with
    | Yans l -> l
    | _ -> failwith "bad artefact"

  let sum yans weights =
    List.fold_left2 (fun sum yan weights ->
        let x =
          match (yan : Artefact.yan) with
          | Yes -> weights.yes
          | Alt -> weights.alt
          | No -> weights.no
        in
        sum + x
      ) 0 yans weights

  let compute_totals ~conf matrix =
    for i = 0 to Matrix.length matrix - 1 do
      let bonus = Matrix.bonus matrix ~i in
      let acc = ref ({ (acc ()) with bonus }) in
      for j = 0 to Matrix.width matrix - 1 do
        let yans = extract @@ Matrix.artefact matrix ~i ~j in
        let weights =
          if Matrix.is_head matrix ~j
          then conf.head_weights
          else conf.weights
        in
        let total = sum yans weights in
        acc :=
          if Matrix.is_head matrix ~j
          then { !acc with head = total; }
          else { !acc with judges = !acc.judges + total }
      done;
      Matrix.set matrix ~i !acc
    done

  let rank ~conf matrix =
    (* some small helpers *)
    let n = Matrix.length matrix in
    let cmp
        { judges = j1; head = h1; bonus = b1; }
        { judges = j2; head = h2; bonus = b2; } =
      CCOrd.(int j2 j1 <?> (int, h2, h1) <?> (int, b2, b1))
    in
    (* comoute total scores  sort the matrix *)
    compute_totals ~conf matrix;
    Matrix.sort matrix ~cmp ~start:0 ~stop:(n - 1);
    Matrix.segments matrix ~cmp ~start:0 ~stop:(n - 1)
      ~f:(fun ~start ~stop ->
          let tie =
            Array.init (stop - start + 1)
              (fun i -> Matrix.target matrix ~i:(start + i))
          in
          One.set (Matrix.ranks matrix) start tie
        );
    (* generate output status *)
    if Matrix.missing_artefacts matrix = 0
    then Status.Complete
    else Status.Partial

end

(* Algorithms - RPSS *)
(* *********************************************************************** *)

module RPSS = struct

  type conf = unit
  [@@deriving yojson]

  type cell = {
    mutable votes : int option;
    mutable sum : int option;
    mutable head : int option;
  }

  type acc = cell array

  let acc_line acc =
    Array.map (function { votes; sum; head; } ->
      match votes, sum, head with
      | None, None, None ->
        PrintBox.asprintf "-"
      | Some 0, None, None ->
        PrintBox.empty
      | Some votes, None, None ->
        PrintBox.asprintf "%d" votes
      | Some votes, Some sum, None ->
        PrintBox.asprintf "%d (%d)" votes sum
      | Some votes, Some sum, Some head ->
        PrintBox.asprintf "%d (%d / %d)" votes sum head
      | _ ->
        PrintBox.asprintf "??"
      ) acc

  let acc n =
    Array.init n (fun _ ->
        { votes = None; sum = None; head = None; })

  let count_votes_up_to ~matrix ~k ~i =
    let res = ref 0 in
    for j = 0 to Matrix.width matrix - 1 do
      match Matrix.artefact matrix ~i ~j with
      | Rank r -> if Rank.to_index r <= k then incr res
      | _ -> failwith "incorrect artefact"
    done;
    !res

  let count_sum_up_to ~matrix ~k ~i =
    let res = ref 0 in
    for j = 0 to Matrix.width matrix - 1 do
      match Matrix.artefact matrix ~i ~j with
      | Rank r -> if Rank.to_index r <= k then res := Rank.rank r + !res
      | _ -> failwith "incorrect artefact"
    done;
    !res

  let cmp_votes ~k = fun cell1 cell2 ->
    CCOrd.(option int) cell2.(k).votes cell1.(k).votes

  let cmp_sum ~k = fun cell1 cell2 ->
    CCOrd.(option int) cell1.(k).sum cell2.(k).sum

  let cmp_head ~k = fun cell1 cell2 ->
    CCOrd.(option int) cell1.(k).head cell2.(k).head

  let set_ranks ~matrix ~start ~stop =
    if start > stop then ()
    else begin
      let tie =
        Array.init (stop - start + 1)
          (fun i -> Matrix.target matrix ~i:(start + i))
      in
      One.set (Matrix.ranks matrix) start tie
    end

  let rec rank_votes ~matrix ~k ~start ~stop =
    let n = Matrix.length matrix in
    let m = Matrix.width matrix in
    if start >= stop then set_ranks ~matrix ~start ~stop
    else if k > n - 1 then
      rank_head ~matrix ~k ~start ~stop
    else begin
      let cursor = ref start in
      for i = start to stop do
        let votes = count_votes_up_to ~matrix ~k ~i in
        (Matrix.get matrix ~i).(k).votes <- Some votes;
        if votes > m / 2
        then (Matrix.swap matrix i !cursor; incr cursor)
      done;

      let have_majority = !cursor - start in
      if have_majority = 0 then
        rank_votes ~matrix ~k:(k + 1) ~start ~stop
      else begin
        if have_majority = 1 then begin
          set_ranks ~matrix ~start ~stop:start;
        end else begin
          Matrix.sort matrix ~start ~stop:(!cursor - 1) ~cmp:(cmp_votes ~k);
          Matrix.segments matrix ~start ~stop:(!cursor - 1)
            ~cmp:(cmp_votes ~k) ~f:(rank_by_sum ~matrix ~k)
        end;
        rank_votes ~matrix ~k:(k + 1) ~start:!cursor ~stop
      end
    end

  and rank_by_sum ~matrix ~k ~start ~stop =
    if start >= stop then set_ranks ~matrix ~start ~stop
    else begin
      for i = start to stop do
        let sum = count_sum_up_to ~matrix ~k ~i in
        (Matrix.get matrix ~i).(k).sum <- Some sum
      done;
      Matrix.sort matrix ~start ~stop ~cmp:(cmp_sum ~k);
      Matrix.segments matrix ~start ~stop
        ~cmp:(cmp_sum ~k) ~f:(rank_votes ~matrix ~k:(k + 1))
    end

  and rank_head ~matrix ~k ~start ~stop =
    match Matrix.head matrix with
    | None -> set_ranks ~matrix ~start ~stop
    | Some j ->
      for i = start to stop do
        let rank =
          match Matrix.artefact matrix ~i ~j with
          | Rank r -> Rank.rank r
          | _ -> failwith "incorrect artefact"
        in
        (Matrix.get matrix ~i).(k).head <- Some rank
      done;
      Matrix.sort matrix ~start ~stop ~cmp:(cmp_head ~k);
      Matrix.segments matrix ~start ~stop ~cmp:(cmp_head ~k)
        ~f:(set_ranks ~matrix)

  let rank ~conf:() matrix =
    if Matrix.missing_artefacts matrix <> 0 then
      Status.Impossible
    else begin
      let n = Matrix.length matrix in
      rank_votes ~matrix ~k:0 ~start:0 ~stop:(n - 1);
      Status.Complete
    end

end
(* Ranking info/explanations *)
(* ************************************************************************* *)

module Res = struct

  type 'target matrix =
    | RPSS of (RPSS.acc, 'target) Matrix.t
    | Yan_weighted of (Yan_weighted.acc, 'target) Matrix.t

  type 'target t = {
    status : Status.t;
    info : 'target matrix;
  }

  let status { status; _ } = status

  let ranking { info; _ } =
    match info with
    | RPSS matrix -> Matrix.ranks matrix
    | Yan_weighted matrix -> Matrix.ranks matrix

  let matrix_box ~pp = function
    | RPSS matrix ->
      Matrix.printbox matrix ~pp
        ~acc_line:RPSS.acc_line ~acc_side:`Right
    | Yan_weighted matrix ->
      Matrix.printbox matrix ~pp
        ~acc_line:Yan_weighted.acc_line ~acc_side:`Left

  let debug ~pp fmt { info; _ } =
    let box = matrix_box ~pp info in
    PrintBox_text.pp fmt box

  let map ~targets ~judges { status; info; } =
    let info =
      match info with
      | RPSS matrix -> RPSS (Matrix.map ~targets ~judges matrix)
      | Yan_weighted matrix -> Yan_weighted (Matrix.map ~targets ~judges matrix)
    in
    { status; info; }

end

(* Wrapper for all algorithm types *)
(* ************************************************************************* *)

module Algorithm = struct

  type t =
    | RPSS of RPSS.conf
    | Yan_weighted of Yan_weighted.conf
  [@@deriving yojson]

  (* Usual functions *)
  (* *********************************************************************** *)

  let print fmt = function
    | RPSS () ->
      Format.fprintf fmt "RPSS"
    | Yan_weighted conf ->
      Yan_weighted.print_conf fmt conf

  (* Algorithms Serialization *)
  (* *********************************************************************** *)

  let to_toml = function
    | RPSS () ->
      Otoml.array [ Otoml.string "RPSS"; ]
    | Yan_weighted conf ->
      Otoml.array ( Otoml.string "Yan_weighted" :: Yan_weighted.conf_to_toml conf)

  let of_toml t =
    match Otoml.get_array Otoml.get_value t with
    | s :: _ when Otoml.get_opt Otoml.get_string s = Some "RPSS" ->
      RPSS ()
    | s :: r when Otoml.get_opt Otoml.get_string s = Some "Yan_weighted" ->
      let conf = Yan_weighted.conf_of_toml r in
      Yan_weighted conf
    | _ ->
      raise (Otoml.Type_error "Not a Ranking algorithm")

  (* Ranking computation *)
  (* *********************************************************************** *)

  let fill_matrix matrix ~get_artefact ~get_bonus =
    for i = 0 to Matrix.length matrix - 1 do
      let target = Matrix.target matrix ~i in
      begin match get_bonus ~target with
        | None -> ()
        | Some bonus -> Matrix.acc_bonus matrix ~i ~bonus
      end;
      for j = 0 to Matrix.width matrix - 1 do
        let judge = Matrix.judge matrix ~j in
        let artefact = get_artefact ~judge ~target in
        Matrix.acc_artefact matrix ~i ~j ~artefact
      done
    done

  let rank ~judges ~head ~targets ~get_artefact ~get_bonus ~t : _ Res.t =
    let aux ~debug:_ ~conf ~acc ~rank =
      let matrix = Matrix.init ~head ~judges ~targets ~acc in
      fill_matrix matrix ~get_artefact ~get_bonus;
      let status = rank ~conf matrix in
      status, matrix
    in
    match (t : t) with
    | RPSS conf ->
      let status, matrix =
        aux ~conf ~acc:RPSS.acc ~rank:RPSS.rank
          ~debug:(fun fmt matrix -> Res.debug ~pp:Id.print fmt {status = Partial; info = RPSS matrix; })
      in
      { status; info = RPSS matrix; }
    | Yan_weighted conf ->
      let status, matrix =
        aux ~conf ~acc:Yan_weighted.acc ~rank:Yan_weighted.rank
          ~debug:(fun fmt matrix -> Res.debug ~pp:Id.print fmt {status = Partial; info = Yan_weighted matrix; })
      in
      { status; info = Yan_weighted matrix; }

  let compute ~judges ~head ~targets ~get_artefact ~get_bonus ~t =
    rank ~judges ~head ~targets ~get_artefact ~get_bonus ~t

end
