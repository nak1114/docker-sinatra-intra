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

ActiveRecord::Schema.define(version: 20170727223917) do

  create_table "products", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "url", null: false
    t.text "name", null: false
    t.bigint "status_id"
    t.text "rename"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status_id"], name: "index_products_on_status_id"
    t.index ["url"], name: "index_products_on_url", unique: true
  end

  create_table "statuses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "short", null: false
    t.string "name", null: false
    t.index ["name"], name: "index_statuses_on_name", unique: true
  end

  create_table "tr_lists", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "url", null: false
    t.text "name", null: false
    t.bigint "status_id"
    t.text "rename"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status_id"], name: "index_tr_lists_on_status_id"
    t.index ["url"], name: "index_tr_lists_on_url", unique: true
  end

  add_foreign_key "products", "statuses"
  add_foreign_key "tr_lists", "statuses"
end
