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

ActiveRecord::Schema.define(version: 20170905154523) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "articles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "r_documents", force: :cascade do |t|
    t.string "recommendable_type"
    t.bigint "recommendable_id"
    t.jsonb "static_tags", default: {}, null: false
    t.jsonb "tags_cache", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recommendable_type", "recommendable_id"], name: "index_r_documents_on_recommendable_type_and_recommendable_id"
    t.index ["static_tags"], name: "index_r_documents_on_static_tags", using: :gin
    t.index ["tags_cache"], name: "index_r_documents_on_tags_cache", using: :gin
  end

  create_table "r_votes", force: :cascade do |t|
    t.string "voter_type"
    t.bigint "voter_id"
    t.string "votable_type"
    t.bigint "votable_id"
    t.integer "weight", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["votable_type", "votable_id"], name: "index_r_votes_on_votable_type_and_votable_id"
    t.index ["voter_id", "voter_type", "votable_id", "votable_type"], name: "one_vote_per_voter_per_votable", unique: true
    t.index ["voter_type", "voter_id"], name: "index_r_votes_on_voter_type_and_voter_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
