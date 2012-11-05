module Calendar = CalendarLib.Calendar

type feed = {
  id : int32;
  url : string option;
  description : string;
  date : Calendar.t;
  author : int32;
  parent : int32 option;
  tags: string list
}

let feed_new data tags = {
  id = data#!id;
  url = data#?url;
  description = data#!description;
  date = data#!timedate;
  author = data#!author;
  parent = data#?parent;
  tags = tags
}

let get_comments_of_feed a l =
  List.filter (fun x -> x.id = a.id) l

let get_others_of_feed a l =
  List.filter (fun x -> x.id <> a.id) l

let links_of_tags tags =
  List.fold_left (fun acc tag ->
    let link = Html.a ~a: [Html.a_class ["tags"]] ~service: Services.tag_feed [Html.pcdata tag] (None, tag) in
    acc @ [Html.pcdata " "; link]
  ) [] tags

let to_html self =
  let content = match self.url with
    | Some l -> let url_service =
                  Eliom_service.external_service
                    l []
                    Eliom_parameter.unit () in
                Html.a ~a: [Html.a_class ["postitle"]] ~service: url_service
                  [Html.pcdata self.description] ()
    | None -> Html.pcdata self.description in
  Db.get_user_name_and_email_with_id self.author >>= fun author ->
  User.get_userid () >>= (function
    | None -> Lwt.return false
    | Some userid ->
        Db.is_feed_author self.id userid
        >>= fun x ->
        User.is_admin ()
        >>= fun y ->
        Lwt.return (x || y)
  )
  >>= fun is_author ->
  Db.count_comments self.id >>= fun comments ->
  Lwt.return (
    List.flatten [
      [Html.img
          ~a: [Html.a_class ["left"]]
          ~alt: (author#!name)
          ~src: (
            Html.make_uri
              ~service: (Utils.get_gravatar (author#!email)) (40, "identicon")
          )
          ();
       content;
       Html.br ();
       Html.pcdata ("Publié le " ^ (Utils.string_of_calendar self.date) ^ " par ");
       Html.a Services.author_feed [Html.pcdata (author#!name)] (None, author#!name);
      ];
      [Html.br ();
       (* TODO : afficher "n commentaire(s)" *)
       Html.a
         Services.view_feed
         (let n = Int64.to_int comments#!n
         in match n with
           | 0
           | 1 -> [Html.pcdata ((string_of_int n) ^ " commentaire ")]
           | n -> [Html.pcdata ((string_of_int n) ^ " commentaires ")])
         (* [Html.pcdata (string_to_int (Int64.to_int comments)) " commentaires "] *)
         (* url_of_title or url_of_desc ? *)
         (Int32.to_int self.id, Utils.strip self.description);
       Html.pcdata "Tags: "
      ];
      links_of_tags self.tags;
      (if is_author then
          [Html.a Services.delete_feed [Html.pcdata " (supprimer ?)"] self.id]
       else []
      );
    ]
  )

let to_atom self =
  Db.get_user_name_and_email_with_id self.author >>= fun author ->
  Lwt.return (match self.url with
    | Some l -> Atom_feed.entry
                  ~updated: self.date
                  ~id: (Html.Xml.uri_of_string l)
                  ~title: (Atom_feed.plain self.description) (* title is description ? *)
                [Atom_feed.authors [Atom_feed.author author#!name]]
    | None -> Atom_feed.entry
                  ~updated: self.date
                  ~id: (Html.Xml.uri_of_string (Int32.to_string self.id))
                  ~title: (Atom_feed.plain self.description) (* title is description ? *)
                [Atom_feed.authors [Atom_feed.author author#!name]]
  )
