
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

let prefix = "/api"

type ('params, 'res, 't) get = 't
  constraint 'params = < .. >
  constraint 't = <
    url : 'params -> Url.t;
    url_template : Url.template;
    result_schema : 'res Schema.t;
    .. >

type ('params, 'payload, 't) post = 't
  constraint 'params = < .. >
  constraint 't = <
    url : 'params -> Url.t;
    url_template : Url.template;
    payload_schema : 'payload Schema.t;
    .. >

(* Event List *)
(* ************************************************************************* *)

(* TODO: restrict the list of events to all events within a (reasonable)
   time frame *)

module Event = struct

  let list : _ get = object(self)
    method url_template = "/events"
    method url _params = self#url_template
    method result_schema = Types.EventList.schema
  end

  let get : _ get = object(self)
    method url_template = "/event/:id"
    method param_event_id = Url.int_param ":id"
    method url params =
      Url.build ~prefix self#url_template [
        Url.Param (self#param_event_id, params#id);
      ]
    method result_schema = Types.Event.schema
  end

end
