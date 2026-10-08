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

ActiveRecord::Schema[8.1].define(version: 2026_10_07_130200) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "announcement_reads", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "announcement_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["announcement_id"], name: "index_announcement_reads_on_announcement_id"
    t.index ["user_id", "announcement_id"], name: "index_announcement_reads_on_user_id_and_announcement_id", unique: true
    t.index ["user_id"], name: "index_announcement_reads_on_user_id"
  end

  create_table "announcements", force: :cascade do |t|
    t.integer "admin_id", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_announcements_on_admin_id"
    t.index ["published_at"], name: "index_announcements_on_published_at"
  end

  create_table "categories", force: :cascade do |t|
    t.integer "parent_id"
    t.string "name", null: false
    t.string "slug", null: false
    t.string "icon_key"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "conversations", force: :cascade do |t|
    t.integer "listing_id", null: false
    t.integer "buyer_id", null: false
    t.datetime "last_message_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_conversations_on_buyer_id"
    t.index ["last_message_at"], name: "index_conversations_on_last_message_at"
    t.index ["listing_id", "buyer_id"], name: "index_conversations_on_listing_id_and_buyer_id", unique: true
    t.index ["listing_id"], name: "index_conversations_on_listing_id"
  end

  create_table "favorites", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "listing_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id"], name: "index_favorites_on_listing_id"
    t.index ["user_id", "listing_id"], name: "index_favorites_on_user_id_and_listing_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "forum_boards", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "description"
    t.string "icon_key"
    t.string "kind", null: false
    t.integer "position", default: 0, null: false
    t.integer "topics_count", default: 0, null: false
    t.integer "posts_count", default: 0, null: false
    t.datetime "last_activity_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_forum_boards_on_slug", unique: true
  end

  create_table "forum_likes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "forum_topic_id"
    t.integer "forum_post_id"
    t.datetime "created_at", null: false
    t.index ["forum_post_id"], name: "index_forum_likes_on_forum_post_id"
    t.index ["user_id", "forum_post_id"], name: "index_forum_likes_on_user_id_and_forum_post_id", unique: true, where: "forum_post_id IS NOT NULL"
    t.index ["user_id", "forum_topic_id"], name: "index_forum_likes_on_user_id_and_forum_topic_id", unique: true, where: "forum_topic_id IS NOT NULL"
    t.index ["user_id"], name: "index_forum_likes_on_user_id"
  end

  create_table "forum_posts", force: :cascade do |t|
    t.integer "forum_topic_id", null: false
    t.integer "user_id", null: false
    t.text "body", null: false
    t.datetime "edited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "likes_count", default: 0, null: false
    t.integer "reply_to_post_id"
    t.boolean "reply_to_deleted", default: false, null: false
    t.index ["forum_topic_id", "created_at"], name: "index_forum_posts_on_forum_topic_id_and_created_at"
    t.index ["forum_topic_id"], name: "index_forum_posts_on_forum_topic_id"
    t.index ["user_id"], name: "index_forum_posts_on_user_id"
  end

  create_table "forum_topics", force: :cascade do |t|
    t.integer "forum_board_id", null: false
    t.integer "user_id", null: false
    t.string "kind", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.boolean "pinned", default: false, null: false
    t.boolean "locked", default: false, null: false
    t.integer "posts_count", default: 0, null: false
    t.integer "views_count", default: 0, null: false
    t.datetime "last_activity_at"
    t.datetime "edited_at"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "likes_count", default: 0, null: false
    t.integer "solved_post_id"
    t.datetime "solved_at"
    t.index ["forum_board_id", "pinned", "last_activity_at"], name: "idx_on_forum_board_id_pinned_last_activity_at_a87dd06fe0"
    t.index ["forum_board_id"], name: "index_forum_topics_on_forum_board_id"
    t.index ["user_id"], name: "index_forum_topics_on_user_id"
  end

  create_table "listing_compatible_categories", force: :cascade do |t|
    t.integer "listing_id", null: false
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_listing_compatible_categories_on_category_id"
    t.index ["listing_id", "category_id"], name: "index_lcc_on_listing_and_category", unique: true
    t.index ["listing_id"], name: "index_listing_compatible_categories_on_listing_id"
  end

  create_table "listings", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "category_id", null: false
    t.integer "part_id"
    t.string "title", null: false
    t.text "description", null: false
    t.string "condition", null: false
    t.integer "price", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "seasons_used"
    t.string "city", null: false
    t.string "district"
    t.boolean "show_phone", default: false, null: false
    t.string "status", default: "active", null: false
    t.string "removal_reason"
    t.datetime "removed_at"
    t.datetime "published_at"
    t.integer "view_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_listings_on_category_id"
    t.index ["part_id"], name: "index_listings_on_part_id"
    t.index ["published_at"], name: "index_listings_on_published_at"
    t.index ["status"], name: "index_listings_on_status"
    t.index ["user_id"], name: "index_listings_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "conversation_id", null: false
    t.integer "sender_id", null: false
    t.text "body", null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "actor_id", null: false
    t.string "kind", null: false
    t.integer "forum_topic_id"
    t.integer "forum_post_id"
    t.integer "count", default: 1, null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["user_id", "kind", "forum_topic_id", "forum_post_id"], name: "index_notifications_on_dedupe"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "parts", force: :cascade do |t|
    t.string "code", null: false
    t.string "slug", null: false
    t.string "name", null: false
    t.string "brand"
    t.integer "category_id", null: false
    t.text "description"
    t.json "specs", default: [], null: false
    t.string "status", default: "pending", null: false
    t.integer "suggested_by_id"
    t.string "reject_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_parts_on_category_id"
    t.index ["code"], name: "index_parts_on_code", unique: true
    t.index ["slug"], name: "index_parts_on_slug", unique: true
    t.index ["status"], name: "index_parts_on_status"
    t.index ["suggested_by_id"], name: "index_parts_on_suggested_by_id"
  end

  create_table "reports", force: :cascade do |t|
    t.integer "listing_id", null: false
    t.integer "reporter_id", null: false
    t.string "reason", null: false
    t.text "details"
    t.string "status", default: "open", null: false
    t.integer "resolved_by_id"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id"], name: "index_reports_on_listing_id"
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.index ["resolved_by_id"], name: "index_reports_on_resolved_by_id"
    t.index ["status"], name: "index_reports_on_status"
  end

  create_table "saved_searches", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name"
    t.json "params", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "created_at"], name: "index_saved_searches_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_saved_searches_on_user_id"
  end

  create_table "site_stats", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", limit: 8, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_site_stats_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "full_name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "city", null: false
    t.string "team_name"
    t.string "phone"
    t.string "role", default: "user", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "announcement_reads", "announcements"
  add_foreign_key "announcement_reads", "users"
  add_foreign_key "announcements", "users", column: "admin_id"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "conversations", "listings"
  add_foreign_key "conversations", "users", column: "buyer_id"
  add_foreign_key "favorites", "listings"
  add_foreign_key "favorites", "users"
  add_foreign_key "forum_likes", "users"
  add_foreign_key "forum_posts", "forum_topics"
  add_foreign_key "forum_posts", "users"
  add_foreign_key "forum_topics", "forum_boards"
  add_foreign_key "forum_topics", "users"
  add_foreign_key "listing_compatible_categories", "categories"
  add_foreign_key "listing_compatible_categories", "listings"
  add_foreign_key "listings", "categories"
  add_foreign_key "listings", "parts"
  add_foreign_key "listings", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "parts", "categories"
  add_foreign_key "parts", "users", column: "suggested_by_id"
  add_foreign_key "reports", "listings"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "reports", "users", column: "resolved_by_id"
  add_foreign_key "saved_searches", "users"
end
