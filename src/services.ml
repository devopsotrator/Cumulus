let atom =
  Eliom_service.service
    ~path: ["cumulus.atom"]
    ~get_params: Eliom_parameter.unit
    ()

let main =
  Eliom_service.service
    ~path: [""]
    ~get_params: (Eliom_parameter.opt (Eliom_parameter.int "page"))
    ()

let view_feed =
  Eliom_service.service
    ~path:["view"]
    ~get_params: Eliom_parameter.(suffix (int "id" ** string "name"))
    ()

let append_feed =
  Eliom_service.post_coservice'
    ~post_params: Eliom_parameter.((string "url") **
                                      (string "desc") **
                                      (string "tags"))
    ()

let author_feed =
  Eliom_service.service
    ~path: [""]
    ~get_params: Eliom_parameter.(opt (int "page") ** string "username")
    ()

let tag_feed =
  Eliom_service.service
    ~path: [""]
    ~get_params: Eliom_parameter.(opt (int "page") ** string "tag")
    ()

let auth =
  Eliom_service.post_coservice'
    ~post_params: Eliom_parameter.((string "username") ** (string "password"))
    ()

let add_user =
  Eliom_service.post_coservice'
    ~post_params: Eliom_parameter.((string "username") **
                                      (string "password") **
                                      (string "password_check") **
                                      (string "email"))
    ()

let append_link_comment =
  Eliom_service.post_coservice'
    ~post_params: Eliom_parameter.((int "id") **
                                   (string "url") **
                                   (string "desc") **
                                   (string "tags"))
    ()

let append_desc_comment =
  Eliom_service.post_coservice'
    ~post_params: Eliom_parameter.((int "id") **
                                   (string "desc"))
    ()

let update_user_mail =
  Eliom_service.post_coservice'
    ~post_params: Eliom_parameter.((string "email"))
    ()

let update_user_password =
  Eliom_service.post_coservice'
    ~post_params: Eliom_parameter.((string "password") **
                                      (string "password_check"))
    ()

let update_user_feeds_per_page =
  Eliom_service.post_coservice'
    ~post_params: Eliom_parameter.((int "feeds_per_page"))
    ()

let registration =
  Eliom_service.service
    ~path: ["registration"]
    ~get_params: Eliom_parameter.unit
    ()

let disconnect =
  Eliom_service.post_coservice'
    ~post_params: Eliom_parameter.unit
    ()

let preferences =
  Eliom_service.service
    ~path: ["preferences"]
    ~get_params: Eliom_parameter.unit
   ()

let comment =
  Eliom_service.service
    ~path: ["comment"]
    ~get_params: Eliom_parameter.(suffix ((int "id") ** string "name"))
    ()

let delete_feed =
  Eliom_service.coservice'
    ~get_params:(Eliom_parameter.int32 "id")
    ()