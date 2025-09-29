# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_28_000002) do
  create_table "infomations", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.date "info_date"
    t.text "info_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "m_cars", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "car_code"
    t.string "car_reg_code"
    t.integer "section_code"
    t.string "car_maker"
    t.integer "type_code"
    t.string "itaku_code"
    t.integer "delete_flg"
    t.string "last_up_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["car_code"], name: "idx_m_cars_car_code"
  end

  create_table "m_collect_industs", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "cust_kbn"
    t.string "cust_code"
    t.integer "indust_kbn"
    t.integer "tree_no"
    t.integer "unit_kbn"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cust_kbn", "cust_code", "indust_kbn"], name: "idx_m_collect_industs_cust_kbn_cust_code_indust_kbn"
  end

  create_table "m_combo_bigs", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "class_1"
    t.string "class_name"
    t.string "class_namea"
    t.string "system_name"
    t.integer "system_flg"
    t.integer "delete_flg"
    t.string "last_up_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "m_combos", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "class_1"
    t.integer "class_2"
    t.integer "class_code"
    t.string "class_name"
    t.string "class_namea"
    t.string "value"
    t.string "value2"
    t.string "value3"
    t.string "value4"
    t.string "value5"
    t.integer "system_flg"
    t.integer "delete_flg"
    t.string "last_up_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["class_1", "class_2", "class_code"], name: "idx_m_combos_class_1_2_code"
  end

  create_table "m_companies", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "username"
    t.string "password"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "m_custom_rundates", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "m_custom_id", null: false
    t.integer "run_week", default: 0, null: false
    t.integer "run_yobi", null: false
    t.integer "item_kbn", null: false
    t.integer "unit_kbn"
    t.string "itaku_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_kbn"], name: "index_m_custom_rundates_on_item_kbn"
    t.index ["m_custom_id", "run_week", "run_yobi", "item_kbn"], name: "idx_custom_rundates_on_mcustom_and_week_yobi_item", unique: true
    t.index ["m_custom_id"], name: "index_m_custom_rundates_on_m_custom_id"
    t.index ["run_week"], name: "index_m_custom_rundates_on_run_week"
    t.index ["run_yobi"], name: "index_m_custom_rundates_on_run_yobi"
  end

  create_table "m_customs", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "cust_kbn"
    t.string "cust_code"
    t.string "cust_name"
    t.string "cust_namek"
    t.float "latitude"
    t.float "longitude"
    t.string "zip_code"
    t.string "addr_1"
    t.string "addr_2"
    t.string "addr_3"
    t.string "tel_no"
    t.string "fax_no"
    t.string "memo"
    t.integer "addr_codel1"
    t.integer "addr_codel2"
    t.integer "addr_codel3"
    t.boolean "gmaps"
    t.integer "delete_flg"
    t.string "last_up_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "admin_code"
    t.integer "admin_type"
    t.integer "use_content"
    t.datetime "shinsei_date"
    t.datetime "haishi_date"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer "setai_count"
    t.integer "use_count"
    t.integer "district_code"
    t.string "district_name"
    t.integer "seq"
    t.string "icon_file_name"
    t.string "icon_content_type"
    t.integer "icon_file_size"
    t.datetime "icon_updated_at"
    t.index ["cust_kbn", "cust_code"], name: "idx_m_customs_cust_kbn_code"
    t.index ["cust_kbn", "cust_name", "delete_flg"], name: "idx_m_customs_cust_kbn_cust_name_delete_flg"
    t.index ["cust_kbn", "latitude", "longitude"], name: "idx_m_customs_cust_kbn_latitude_longitude"
  end

  create_table "m_drivers", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "driver_code"
    t.string "driver_name"
    t.integer "section_code"
    t.string "itaku_code"
    t.integer "delete_flg"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["driver_code"], name: "idx_m_drivers_driver_code", unique: true
  end

  create_table "m_mail_settings", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "setting_kbn"
    t.string "user_name"
    t.string "mail_pass"
    t.string "address"
    t.string "domain"
    t.string "port"
    t.string "authentication"
    t.string "last_up_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name"
    t.string "reply_to_mail"
  end

  create_table "m_route_areas", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "route_code"
    t.integer "tree_no"
    t.text "latlng"
    t.string "last_up_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["route_code"], name: "idx_m_route_areas_route_code"
  end

  create_table "m_route_point_rundates", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "m_route_point_id", null: false
    t.integer "run_week", default: 0, null: false
    t.integer "run_yobi", null: false
    t.integer "item_kbn", null: false
    t.integer "unit_kbn"
    t.string "itaku_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_kbn"], name: "index_m_route_point_rundates_on_item_kbn"
    t.index ["m_route_point_id", "run_week", "run_yobi", "item_kbn"], name: "idx_point_rundates_on_point_week_yobi_item", unique: true
    t.index ["m_route_point_id"], name: "index_m_route_point_rundates_on_m_route_point_id"
    t.index ["run_week"], name: "index_m_route_point_rundates_on_run_week"
    t.index ["run_yobi"], name: "index_m_route_point_rundates_on_run_yobi"
  end

  create_table "m_route_points", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "route_code"
    t.integer "tree_no"
    t.integer "cust_kbn"
    t.string "cust_code"
    t.string "last_up_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cust_kbn", "cust_code", "route_code"], name: "idx_m_route_points_cust_kbn_cust_code_route_code"
    t.index ["route_code", "cust_kbn", "cust_code"], name: "idx_m_route_points_route_code_cust_kbn_cust_code"
    t.index ["route_code"], name: "idx_m_route_points_route_code"
  end

  create_table "m_route_recommends", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "route_code"
    t.integer "priority"
    t.text "latlng", size: :long
    t.integer "carrun_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "latlng_origin", size: :long
    t.index ["route_code", "priority"], name: "idx_m_route_recommends_route_code_priority"
  end

  create_table "m_route_rundates", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "route_code"
    t.integer "tree_no"
    t.integer "run_week"
    t.integer "run_yobi"
    t.integer "item_kbn"
    t.string "itaku_code"
    t.string "last_up_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "unit_kbn"
    t.index ["item_kbn", "tree_no"], name: "idx_m_route_rundate_item_kbn_tree_no"
    t.index ["route_code"], name: "idx_m_route_rundates_route_code"
  end

  create_table "m_routes", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "route_code"
    t.string "route_name"
    t.integer "route_cust_kbn"
    t.integer "route_itaku_kbn"
    t.integer "cust_kbn"
    t.string "cust_code"
    t.integer "route_spot_kbn"
    t.string "car_code"
    t.integer "yobi_kbn"
    t.integer "delete_flg"
    t.string "last_up_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "itaku_code"
    t.integer "area_color"
    t.integer "use_item_flg"
    t.index ["route_code"], name: "idx_m_routes_route_code"
  end

  create_table "m_users", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "user_id"
    t.string "user_name"
    t.string "password"
    t.integer "authority"
    t.integer "delete_flg"
    t.string "last_up_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "t_car_messages", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "car_id"
    t.datetime "time"
    t.integer "importance_flg"
    t.text "message"
    t.integer "response_type"
    t.integer "response_answer"
    t.datetime "response_time"
    t.date "start_date"
    t.date "end_date"
    t.integer "delete_flg"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "t_carrun_lists", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "out_timing"
    t.string "car_code"
    t.integer "tree_no"
    t.integer "work_kind"
    t.integer "work_kbn"
    t.float "latitude"
    t.float "longitude"
    t.string "address"
    t.datetime "work_timing"
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "end_timing"
    t.index ["out_timing", "car_code", "tree_no"], name: "idx_t_carrun_lists_out_timing_car_code_tree_no"
  end

  create_table "t_carrun_memos", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "carrun_id"
    t.integer "cust_kbn"
    t.string "cust_code"
    t.datetime "finish_timing"
    t.string "memo_file_name"
    t.string "memo_content_type"
    t.integer "memo_file_size"
    t.datetime "memo_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["carrun_id", "cust_kbn", "cust_code", "finish_timing", "memo_file_name"], name: "idx_t_carrun_memos_carrun_id_cust_kbn_code_finish_memo", unique: true
    t.index ["carrun_id", "cust_kbn", "cust_code"], name: "idx_t_carrun_memos_carrun_id_cust_kbn_cust_code"
    t.index ["cust_kbn", "cust_code"], name: "idx_t_carrun_memos_cust_kbn_cust_code"
    t.index ["finish_timing", "cust_kbn", "cust_code"], name: "idx_t_carrun_memos_finish_timing_cust_kbn_cust_code"
    t.index ["memo_file_name"], name: "idx_t_carrun_memos_memo_file_name"
  end

  create_table "t_carruns", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "out_timing"
    t.string "car_code"
    t.string "route_code"
    t.datetime "in_timing"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "input_flg"
    t.string "driver_code"
    t.string "sub_driver_code1"
    t.string "sub_driver_code2"
    t.integer "use_item_flg"
    t.integer "mater_out"
    t.integer "mater_in"
    t.integer "run_distance"
    t.index ["out_timing", "car_code"], name: "idx_t_carruns_out_timing_car_code", unique: true
    t.index ["out_timing", "route_code"], name: "idx_t_carruns_out_timing_route_code"
  end

  create_table "t_change_shinseis", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "cust_kbn"
    t.string "cust_code"
    t.string "addr_1"
    t.string "addr_2"
    t.string "addr_3"
    t.float "latitude"
    t.float "longitude"
    t.string "admin_code"
    t.string "route_code"
    t.integer "shinsei_kbn"
    t.datetime "shinsei_date"
    t.datetime "kibou_date"
    t.integer "confirm_flg"
    t.string "last_up_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cust_name"
    t.string "tel_no"
    t.string "fax_no"
    t.string "email"
    t.integer "admin_type"
    t.integer "district_code"
    t.string "district_name"
    t.integer "seq"
    t.integer "use_content"
    t.integer "setai_count"
    t.integer "use_count"
    t.string "memo"
    t.index ["cust_kbn", "cust_code"], name: "idx_t_change_shinseis_cust_kbn_code"
  end

  create_table "t_collect_details", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "out_timing"
    t.string "car_code"
    t.integer "spot_no"
    t.integer "item_kbn"
    t.integer "item_code"
    t.string "item_name"
    t.decimal "item_weight", precision: 18, scale: 2
    t.decimal "item_count", precision: 18, scale: 2
    t.integer "unload_no"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "unit_kbn"
    t.index ["out_timing", "car_code", "spot_no"], name: "idx_t_collect_details_out_timing_car_code_spot_no"
  end

  create_table "t_collect_lists", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "out_timing"
    t.string "car_code"
    t.integer "spot_no"
    t.integer "cust_kbn"
    t.string "cust_code"
    t.datetime "finish_timing"
    t.datetime "leave_timing"
    t.datetime "arrive_timing"
    t.float "mikaishu_count"
    t.integer "mikaishu_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cust_name"
    t.float "latitude"
    t.float "longitude"
    t.integer "delete_flg"
    t.index ["finish_timing", "out_timing", "car_code", "spot_no"], name: "idx_t_collect_lists_finish_timing_out_timing_car_code_spot_no"
    t.index ["latitude", "longitude"], name: "idx_t_collect_lists_latitude_longitude"
    t.index ["out_timing", "car_code", "cust_kbn", "cust_code"], name: "idx_t_collect_lists_out_timing_car_code_cust_kbn_code"
    t.index ["out_timing", "car_code", "spot_no"], name: "idx_t_collect_lists_out_timing_car_code_spot_no", unique: true
  end

  create_table "t_custom_memos", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "cust_kbn"
    t.string "cust_code"
    t.datetime "memo_time"
    t.text "memo"
    t.integer "user_id"
    t.string "itaku_code"
    t.integer "itaku_flg"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cust_kbn", "cust_code"], name: "idx_t_custom_memos_cust_kbn_cust_code"
  end

  create_table "t_fee_gasses", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "out_timing"
    t.string "car_code"
    t.datetime "gass_timing"
    t.integer "gass_kbn"
    t.float "latitude"
    t.float "longitude"
    t.decimal "quantity", precision: 18, scale: 2
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["out_timing", "car_code"], name: "idx_t_fee_gasses_out_timing_car_code"
  end

  create_table "t_log_hists", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "log_time"
    t.integer "user_id"
    t.integer "menu_id"
    t.integer "change_type"
    t.text "change_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "t_mail_hists", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "cust_kbn"
    t.string "cust_code"
    t.datetime "send_date"
    t.string "send_subject"
    t.string "send_body", limit: 5000
    t.string "send_file"
    t.string "send_email"
    t.integer "delete_flg"
    t.string "last_up_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cust_kbn", "cust_code"], name: "idx_t_mail_hists_cust_kbn_code"
  end

  create_table "t_tracks", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "out_timing"
    t.string "deviceid"
    t.string "car_code"
    t.string "route_code"
    t.datetime "time"
    t.float "latitude"
    t.float "longitude"
    t.float "accuracy"
    t.integer "gps_count"
    t.integer "net_status"
    t.integer "failure_flg"
    t.integer "speed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["out_timing", "car_code"], name: "idx_t_tracks_out_timing_car_code"
    t.index ["time", "car_code"], name: "idx_t_tracks_time_car_code"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "user_id", default: "", null: false
    t.string "user_name", default: "", null: false
    t.string "email", default: ""
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "authority"
    t.integer "login_authority"
    t.string "itaku_code"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["user_id"], name: "index_users_on_user_id", unique: true
  end

  add_foreign_key "m_custom_rundates", "m_customs"
  add_foreign_key "m_route_point_rundates", "m_route_points"
end
