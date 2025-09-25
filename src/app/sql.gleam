//// This module contains the code to run the sql queries defined in
//// `./src/app/sql`.
//// > 🐿️ This module was generated automatically using v4.4.1 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `count_active_brigades` query
/// defined in `./src/app/sql/count_active_brigades.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CountActiveBrigadesRow {
  CountActiveBrigadesRow(count: Int)
}

/// Runs the `count_active_brigades` query
/// defined in `./src/app/sql/count_active_brigades.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn count_active_brigades(
  db: pog.Connection,
) -> Result(pog.Returned(CountActiveBrigadesRow), pog.QueryError) {
  let decoder = {
    use count <- decode.field(0, decode.int)
    decode.success(CountActiveBrigadesRow(count:))
  }

  "SELECT COUNT(id)
FROM public.brigade
WHERE is_active = TRUE;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_brigade_members` query
/// defined in `./src/app/sql/get_brigade_members.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetBrigadeMembersRow {
  GetBrigadeMembersRow(
    full_name: String,
    role_name: Option(String),
    description: Option(String),
  )
}

/// Runs the `get_brigade_members` query
/// defined in `./src/app/sql/get_brigade_members.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_brigade_members(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(GetBrigadeMembersRow), pog.QueryError) {
  let decoder = {
    use full_name <- decode.field(0, decode.string)
    use role_name <- decode.field(1, decode.optional(decode.string))
    use description <- decode.field(2, decode.optional(decode.string))
    decode.success(GetBrigadeMembersRow(full_name:, role_name:, description:))
  }

  "SELECT
    u.full_name,
    r.role_name,
    r.description
FROM public.user_account AS u
LEFT JOIN
    public.user_role AS r
    ON u.role_id = r.id
INNER JOIN
    public.query_brigade_members_id($1) AS brigade_members (id)
    ON u.id = brigade_members.id;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_fellow_brigade_members` query
/// defined in `./src/app/sql/get_fellow_brigade_members.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetFellowBrigadeMembersRow {
  GetFellowBrigadeMembersRow(
    full_name: String,
    role_name: Option(String),
    description: Option(String),
  )
}

/// Runs the `get_fellow_brigade_members` query
/// defined in `./src/app/sql/get_fellow_brigade_members.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_fellow_brigade_members(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(GetFellowBrigadeMembersRow), pog.QueryError) {
  let decoder = {
    use full_name <- decode.field(0, decode.string)
    use role_name <- decode.field(1, decode.optional(decode.string))
    use description <- decode.field(2, decode.optional(decode.string))
    decode.success(GetFellowBrigadeMembersRow(
      full_name:,
      role_name:,
      description:,
    ))
  }

  "SELECT
    u.full_name,
    r.role_name,
    r.description
FROM QUERY_FELLOW_BRIGADE_MEMBERS_ID($1) AS fellow_members (id)
INNER JOIN
    public.user_account AS u
    ON fellow_members.id = u.id
LEFT JOIN
    public.user_role AS r
    ON u.role_id = r.id;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_login_token` query
/// defined in `./src/app/sql/get_login_token.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetLoginTokenRow {
  GetLoginTokenRow(id: Uuid, password_hash: String)
}

/// Runs the `get_login_token` query
/// defined in `./src/app/sql/get_login_token.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_login_token(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(GetLoginTokenRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use password_hash <- decode.field(1, decode.string)
    decode.success(GetLoginTokenRow(id:, password_hash:))
  }

  "SELECT
    u.id,
    u.password_hash
FROM public.user_account AS u
WHERE u.registration = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_occurences_by_applicant` query
/// defined in `./src/app/sql/get_occurences_by_applicant.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetOccurencesByApplicantRow {
  GetOccurencesByApplicantRow(
    description: Option(String),
    category: Option(String),
    subcategory: Option(String),
    created_at: Option(Timestamp),
    resolved_at: Option(Timestamp),
    location: List(Float),
    reference_point: String,
    loss_percentage: Option(Float),
  )
}

/// Runs the `get_occurences_by_applicant` query
/// defined in `./src/app/sql/get_occurences_by_applicant.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_occurences_by_applicant(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(GetOccurencesByApplicantRow), pog.QueryError) {
  let decoder = {
    use description <- decode.field(0, decode.optional(decode.string))
    use category <- decode.field(1, decode.optional(decode.string))
    use subcategory <- decode.field(2, decode.optional(decode.string))
    use created_at <- decode.field(3, decode.optional(pog.timestamp_decoder()))
    use resolved_at <- decode.field(4, decode.optional(pog.timestamp_decoder()))
    use location <- decode.field(5, decode.list(decode.float))
    use reference_point <- decode.field(6, decode.string)
    use loss_percentage <- decode.field(
      7,
      decode.optional(pog.numeric_decoder()),
    )
    decode.success(GetOccurencesByApplicantRow(
      description:,
      category:,
      subcategory:,
      created_at:,
      resolved_at:,
      location:,
      reference_point:,
      loss_percentage:,
    ))
  }

  "SELECT
    o.description,
    oc_cat.category_name AS category,
    sub_cat.category_name AS subcategory,
    o.created_at,
    o.resolved_at,
    o.location,
    o.reference_point,
    o.loss_percentage
FROM public.query_all_ocurrences_by_user_id($1) AS oc_list (id)
INNER JOIN public.occurrence AS o
    ON oc_list.id = o.id
LEFT JOIN public.occurrence_category AS oc_cat
    ON o.category_id = oc_cat.id
LEFT JOIN public.occurrence_category AS sub_cat
    ON o.subcategory_id = sub_cat.id;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_user_id_by_registration` query
/// defined in `./src/app/sql/get_user_id_by_registration.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetUserIdByRegistrationRow {
  GetUserIdByRegistrationRow(id: Uuid)
}

/// Runs the `get_user_id_by_registration` query
/// defined in `./src/app/sql/get_user_id_by_registration.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_user_id_by_registration(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(GetUserIdByRegistrationRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(GetUserIdByRegistrationRow(id:))
  }

  "SELECT u.id
FROM public.user_account AS u
WHERE u.registration = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `insert_new_user` query
/// defined in `./src/app/sql/insert_new_user.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn insert_new_user(
  db: pog.Connection,
  arg_1: String,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "INSERT INTO public.user_account (
    full_name,
    registration,
    phone,
    email,
    password_hash
) VALUES (
    $1,
    $2,
    $3,
    $4,
    $5
)
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

// --- Encoding/decoding utils -------------------------------------------------

/// A decoder to decode `Uuid`s coming from a Postgres query.
///
fn uuid_decoder() {
  use bit_array <- decode.then(decode.bit_array)
  case uuid.from_bit_array(bit_array) {
    Ok(uuid) -> decode.success(uuid)
    Error(_) -> decode.failure(uuid.v7(), "Uuid")
  }
}
