let error = Eliom_reference.eref ~scope:Eliom_common.request ""

let get_error () =
  Eliom_reference.get error

let set_error value =
  Eliom_reference.set error value
