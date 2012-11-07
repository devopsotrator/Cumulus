class type ['a] macaque_type = object
  method get : unit
  method nul : Sql.non_nullable
  method t : 'a
end

class type feed = object
  method author : Sql.int32_t macaque_type Sql.t
  method id : Sql.int32_t macaque_type Sql.t
  method timedate : Sql.timestamp_t macaque_type Sql.t
  method title : Sql.string_t macaque_type Sql.t
  method url : Sql.string_t macaque_type Sql.t
end

class type tag = object
  method tag : Sql.string_t macaque_type Sql.t
  method id_feed : Sql.int32_t macaque_type Sql.t
end

type feeds_and_tags = feed list * tag list
type feed_generator = int32 -> int32 -> feeds_and_tags Lwt.t

val get_user_name_and_email_with_id :
  int32 ->
  < email : Sql.string_t macaque_type Sql.t;
  name : Sql.string_t macaque_type Sql.t >
    Lwt.t
val get_user_with_name :
  string ->
  < email : Sql.string_t macaque_type Sql.t;
  id : Sql.int32_t macaque_type Sql.t;
  name : Sql.string_t macaque_type Sql.t;
  password : Sql.string_t macaque_type Sql.t;
  is_admin : Sql.bool_t macaque_type Sql.t;
  feeds_per_page : Sql.int32_t macaque_type Sql.t >
    option Lwt.t
val get_feeds : feed_generator
val get_feeds_with_author : string -> feed_generator
val get_feeds_with_tag : string -> feed_generator
val get_feed_url_with_url :
  string ->
  < url : Sql.string_t macaque_type Sql.t >
    option Lwt.t
val get_feed_with_id :
  int32 ->
  feeds_and_tags Lwt.t

val count_feeds :
  unit ->
  < n : Sql.int64_t macaque_type Sql.t > Lwt.t

val count_feeds_with_author :
  string ->
  < n : Sql.int64_t macaque_type Sql.t > Lwt.t

val count_feeds_with_tag :
  string ->
  < n : Sql.int64_t macaque_type Sql.t > Lwt.t

val add_feed : string -> string -> string list -> int32 -> unit Lwt.t
val add_user : string -> string -> string -> unit Lwt.t

val is_feed_author : int32 -> int32 -> bool Lwt.t
val delete_feed : int32 -> int32 -> unit Lwt.t

val update_user_password : int32 -> string -> unit Lwt.t
val update_user_email : int32 -> string -> unit Lwt.t
val update_user_feeds_per_page : int32 -> int32 -> unit Lwt.t
