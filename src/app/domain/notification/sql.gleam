//// This module contains the code to run the sql queries defined in
//// `./src/app/domain/notification/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `query_active_notifications` query
/// defined in `./src/app/domain/notification/sql/query_active_notifications.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryActiveNotificationsRow {
  QueryActiveNotificationsRow(notification_type: NotificationTypeEnum)
}

///   Find the active notifications from an user
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_active_notifications(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryActiveNotificationsRow), pog.QueryError) {
  let decoder = {
    use notification_type <- decode.field(0, notification_type_enum_decoder())
    decode.success(QueryActiveNotificationsRow(notification_type:))
  }

  "--   Find the active notifications from an user
select np.notification_type
from public.user_notification_preference as np
where
    np.user_id = $1
    and np.enabled = true;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_notification_preferences` query
/// defined in `./src/app/domain/notification/sql/query_notification_preferences.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryNotificationPreferencesRow {
  QueryNotificationPreferencesRow(
    notification_type: NotificationTypeEnum,
    enabled: Bool,
  )
}

///   Find the notification preferences for an user
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_notification_preferences(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryNotificationPreferencesRow), pog.QueryError) {
  let decoder = {
    use notification_type <- decode.field(0, notification_type_enum_decoder())
    use enabled <- decode.field(1, decode.bool)
    decode.success(QueryNotificationPreferencesRow(notification_type:, enabled:))
  }

  "--   Find the notification preferences for an user
select
    np.notification_type,
    np.enabled
from public.user_notification_preference as np
where np.user_id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_notification_preferences` query
/// defined in `./src/app/domain/notification/sql/update_notification_preferences.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateNotificationPreferencesRow {
  UpdateNotificationPreferencesRow(
    notification_type: NotificationTypeEnum,
    enabled: Bool,
  )
}

///   Update user notification preference
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_notification_preferences(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: NotificationTypeEnum,
  arg_3: Bool,
) -> Result(pog.Returned(UpdateNotificationPreferencesRow), pog.QueryError) {
  let decoder = {
    use notification_type <- decode.field(0, notification_type_enum_decoder())
    use enabled <- decode.field(1, decode.bool)
    decode.success(UpdateNotificationPreferencesRow(
      notification_type:,
      enabled:,
    ))
  }

  "--   Update user notification preference
update public.user_notification_preference as np
set
    enabled = $3,
    updated_at = current_timestamp
where
    np.user_id = $1
    and np.notification_type = $2
returning
    new.notification_type,
    new.enabled;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(notification_type_enum_encoder(arg_2))
  |> pog.parameter(pog.bool(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

// --- Enums -------------------------------------------------------------------

/// Corresponds to the Postgres `notification_type_enum` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type NotificationTypeEnum {
  Other
  Traffic
  Emergency
  Fire
}

fn notification_type_enum_decoder() -> decode.Decoder(NotificationTypeEnum) {
  use notification_type_enum <- decode.then(decode.string)
  case notification_type_enum {
    "other" -> decode.success(Other)
    "traffic" -> decode.success(Traffic)
    "emergency" -> decode.success(Emergency)
    "fire" -> decode.success(Fire)
    _ -> decode.failure(Other, "NotificationTypeEnum")
  }
}

fn notification_type_enum_encoder(notification_type_enum) -> pog.Value {
  case notification_type_enum {
    Other -> "other"
    Traffic -> "traffic"
    Emergency -> "emergency"
    Fire -> "fire"
  }
  |> pog.text
}
