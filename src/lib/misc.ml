
module Bit = struct

  let[@inline] set ~index i =
    i lor (1 lsl index)

  let[@inline] is_set ~index i =
    assert (0 <= index && index <= 60);
    let mask = 1 lsl index in
    i land mask <> 0

end
