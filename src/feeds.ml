module Calendar = CalendarLib.Calendar
module UTF8 = Batteries.UTF8

type append_state = Ok | Not_connected | Empty | Already_exist | Invalid_url

let (>>=) = Lwt.(>>=)

let feed_of_db (feed, tags) =
  Lwt.return
    (Feed.feed_new
       feed
       (List.map
          (fun elm -> elm#!tag)
          (List.filter (fun elm -> elm#!id_feed = feed#!id) tags)
       )
    )

let feeds_of_db feeds =
  Lwt_list.map_s (fun x -> feed_of_db (x, snd feeds)) (fst feeds)

let to_somthing f data =
  Lwt_list.map_p (fun feed -> f feed) data

let private_to_html data =
  to_somthing
    (fun feed ->
      Feed.to_html feed >>= (fun elm ->
        Lwt.return (Html.div ~a: [Html.a_class ["line post"]] elm)
      )
    ) data

let comments_to_html id =
  Db_feed.get_feed_with_id id
  >>= feed_of_db
  >>= fun root ->
  Db_feed.get_comments id
  >>= feeds_of_db
  >>= fun comments ->
  let result = Comments.tree_comments [Comments.Sheet root] comments
  in match result with
    | Some tree -> Comments.to_html tree
    | None -> Comments.to_html (Comments.Sheet root)

let branch_to_html id =
  Db_feed.get_feed_with_id id
  >>= feed_of_db
  >>= fun sheet ->
  match sheet.Feed.root with
    | None -> Comments.to_html (Comments.Sheet sheet)
    | Some id ->
        Db_feed.get_feed_with_id id
        >>= feed_of_db
        >>= fun root ->
        Db_feed.get_comments id
        >>= feeds_of_db
        >>= fun comments ->
        let tree =
          Comments.branch_comments (Comments.Sheet sheet) (root :: comments)
        in
        Comments.to_html tree

let to_html feeds = feeds_of_db feeds >>= private_to_html

let feed_id_to_html id =
  Db_feed.get_feed_with_id id
  >>= feed_of_db
  >>= fun feed ->
  private_to_html [feed]

(* FIXME? should atom feed return only a limited number of links ? *)
let to_atom () =
  Db_feed.get_feeds ~starting:0l ~number:Utils.offset ()
  >>= feeds_of_db
  >>= to_somthing Feed.to_atom
  >>= (fun tmp ->
    Lwt.return (
      Atom_feed.feed
        ~updated: (Calendar.make 2012 6 9 17 40 30)
        ~id:"http://cumulus.org"
        ~title: (Atom_feed.plain "An Atom flux")
        tmp
    )
  )

let (event, call_event) =
  let (private_event, call_event) = React.E.create () in
  let event = Eliom_react.Down.of_react private_event in
  (event, call_event)

let strip_and_lowercase x =
  (* (List.map (fun x -> String.lowercase (Utils.strip x)) (Str.split (Str.regexp "[,]+") tags)) *)
  UTF8.to_string (UTF8.lowercase (UTF8.of_string (Utils.strip x)))

let append_feed (url, (description, tags)) =
  User.get_userid () >>= fun userid ->
  match userid with
    | None -> Lwt.return Not_connected
    | (Some author) ->
      if (Utils.string_is_empty description || Utils.string_is_empty tags) then
        Lwt.return Empty
      else if Utils.is_invalid_url url then
        Lwt.return Invalid_url
      else
        Db_feed.get_feed_url_with_url url >>= function
          | (Some _) -> Lwt.return Already_exist
          | None ->
            Db_feed.add_feed
              url
              description
              (List.map strip_and_lowercase (Utils.split tags))
              author >>= fun () ->
            call_event ();
            Lwt.return Ok

let append_link_comment (id, (url, (description, tags))) =
  User.get_userid () >>= fun userid ->
    match userid with
      | None -> Lwt.return Not_connected
      | Some author ->
        if (Utils.string_is_empty description || Utils.string_is_empty tags) then
          Lwt.return Empty
        else if Utils.is_invalid_url url then
          Lwt.return Invalid_url
        else
          Db_feed.get_feed_url_with_url url >>= function
            | Some _ -> Lwt.return Already_exist
            | None ->
              Db_feed.get_feed_with_id (Int32.of_int id) >>= fun feeds_list ->
                let feed = fst feeds_list in
                let parent = feed#!id in
                let root = match feed#?root with
                  | Some root -> root
                  | None -> parent
                in
                Db_feed.add_feed
                  ~root
                  ~parent
                  url
                  description
                  (List.map strip_and_lowercase (Utils.split tags))
                  author >>= fun () ->
                call_event ();
                Lwt.return Ok

let append_desc_comment (id, description) =
  User.get_userid () >>= fun userid ->
    match userid with
      | None -> Lwt.return Not_connected
      | Some author ->
        if Utils.string_is_empty description then
          Lwt.return Empty
        else
          Db_feed.get_feed_with_id (Int32.of_int id) >>= fun feeds_list ->
            let feed = fst feeds_list in
            let parent = feed#!id in
            let root = match feed#?root with
              | Some root -> root
              | None -> parent
            in
            Db_feed.add_desc_comment
              description
              root
              parent
              author >>= fun () ->
            call_event ();
            Lwt.return Ok