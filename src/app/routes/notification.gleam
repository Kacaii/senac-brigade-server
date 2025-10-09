import app/routes/notification/sql

pub fn to_string_pt_br(notification: sql.NotificationTypeEnum) -> String {
  case notification {
    sql.Fire -> "incendio"
    sql.Emergency -> "emergencia"
    sql.Traffic -> "transito"
    sql.Other -> "outros"
  }
}
