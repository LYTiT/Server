# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140618024827) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "comment_views", force: true do |t|
    t.integer  "venue_comment_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comment_views", ["user_id"], name: "index_comment_views_on_user_id", using: :btree
  add_index "comment_views", ["venue_comment_id", "user_id"], name: "index_comment_views_on_venue_comment_id_and_user_id", unique: true, using: :btree
  add_index "comment_views", ["venue_comment_id"], name: "index_comment_views_on_venue_comment_id", using: :btree

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "events", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "start_date"
    t.datetime "end_date"
    t.text     "location_name"
    t.text     "latitude"
    t.text     "longitude"
    t.integer  "venue_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "events_groups", force: true do |t|
    t.integer  "event_id"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "flagged_comments", force: true do |t|
    t.integer  "venue_comment_id"
    t.integer  "user_id"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "flagged_events", force: true do |t|
    t.integer  "event_id"
    t.integer  "user_id"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "flagged_groups", force: true do |t|
    t.integer  "user_id"
    t.integer  "group_id"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "flagged_groups", ["group_id"], name: "index_flagged_groups_on_group_id", using: :btree
  add_index "flagged_groups", ["user_id"], name: "index_flagged_groups_on_user_id", using: :btree

  create_table "groups", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.boolean  "is_public"
    t.string   "password"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "groups", ["deleted_at"], name: "index_groups_on_deleted_at", using: :btree

  create_table "groups_users", force: true do |t|
    t.integer  "user_id"
    t.integer  "group_id"
    t.boolean  "is_admin",          default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "notification_flag", default: true
  end

  create_table "groups_venues", force: true do |t|
    t.integer  "group_id"
    t.integer  "venue_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  add_index "groups_venues", ["user_id"], name: "index_groups_venues_on_user_id", using: :btree

  create_table "lytit_votes", force: true do |t|
    t.integer  "value"
    t.integer  "venue_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "lytit_votes", ["user_id"], name: "index_lytit_votes_on_user_id", using: :btree
  add_index "lytit_votes", ["venue_id"], name: "index_lytit_votes_on_venue_id", using: :btree

  create_table "roles", force: true do |t|
    t.string "name"
  end

  create_table "users", force: true do |t|
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
    t.string   "email",                                                       null: false
    t.string   "encrypted_password",              limit: 128,                 null: false
    t.string   "confirmation_token",              limit: 128
    t.string   "remember_token",                  limit: 128,                 null: false
    t.string   "name"
    t.string   "authentication_token"
    t.boolean  "notify_location_added_to_groups",             default: true
    t.boolean  "notify_events_added_to_groups",               default: true
    t.text     "push_token"
    t.boolean  "notify_venue_added_to_groups",                default: true
    t.integer  "role_id"
    t.boolean  "username_private",                            default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["remember_token"], name: "index_users_on_remember_token", using: :btree
  add_index "users", ["role_id"], name: "index_users_on_role_id", using: :btree

  create_table "venue_comments", force: true do |t|
    t.string   "comment"
    t.string   "media_type"
    t.string   "media_url"
    t.integer  "user_id"
    t.integer  "venue_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "venue_comments", ["user_id"], name: "index_venue_comments_on_user_id", using: :btree
  add_index "venue_comments", ["venue_id"], name: "index_venue_comments_on_venue_id", using: :btree

  create_table "venue_messages", force: true do |t|
    t.string   "message"
    t.integer  "venue_id"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "venue_messages", ["venue_id"], name: "index_venue_messages_on_venue_id", using: :btree

  create_table "venue_ratings", force: true do |t|
    t.integer  "user_id"
    t.integer  "venue_id"
    t.float    "rating"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "venue_ratings", ["user_id"], name: "index_venue_ratings_on_user_id", using: :btree
  add_index "venue_ratings", ["venue_id"], name: "index_venue_ratings_on_venue_id", using: :btree

  create_table "venues", force: true do |t|
    t.string   "name"
    t.float    "rating"
    t.string   "phone_number"
    t.text     "address"
    t.string   "city"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "latitude"
    t.float    "longitude"
    t.float    "google_place_rating"
    t.string   "google_place_key"
    t.string   "country"
    t.string   "postal_code"
    t.text     "formatted_address"
    t.text     "google_place_reference"
    t.datetime "fetched_at"
    t.float    "r_up_votes"
    t.float    "r_down_votes"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer  "user_id"
    t.string   "menu_link"
  end

  add_index "venues", ["user_id"], name: "index_venues_on_user_id", using: :btree

end
