import app/database
import app/routes/role
import app/routes/user
import app/routes/user/sql
import app/web.{type Context}
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp
import youid/uuid


pub fn handle_request(req: wisp.Request, ctx: Context,id user_id: String) -> wisp.Response {
  use <- wisp.require_method(req, http.Put)
  use json_data <- wisp.require_json(req)
  case x (json_data, update_user_decoder){
   Error(_) -> wisp.unprocessable_content()
   Ok(update_value) -> try_update_user()
  }
}

fn try_update_user(ctx: Context, update_value: UpdateUser, req: wisp.Request){
  auth_user_from_cookie(req: req, cookie_name: "USER_ID")
}

pub fn update_user_decoder(){
    use full_name <- decode.field("full_name":String)
    use email <- decode.field("email":String)
    use phone <- decode.field("phone":String)

    decode.success(UpdateUser)
}

type UpdateUser {
    UpdateUser(full_name:String, email:String, phone:String)
}