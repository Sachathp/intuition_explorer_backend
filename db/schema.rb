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

ActiveRecord::Schema[8.0].define(version: 2025_11_21_132517) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "atoms", force: :cascade do |t|
    t.string "did", null: false
    t.text "description"
    t.decimal "current_signal_value", precision: 20, scale: 8, default: "0.0"
    t.decimal "share_price", precision: 20, scale: 8, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image"
    t.string "type"
    t.string "creator_id"
    t.string "wallet_id"
    t.bigint "block_number"
    t.string "emoji"
    t.jsonb "data"
    t.decimal "total_shares", precision: 30, scale: 18, default: "0.0"
    t.integer "deposits_count", default: 0
    t.integer "positions_count", default: 0
    t.decimal "growth_24h_percent", precision: 10, scale: 4, default: "0.0"
    t.decimal "growth_7d_percent", precision: 10, scale: 4, default: "0.0"
    t.decimal "first_price_24h", precision: 30, scale: 18
    t.decimal "first_price_7d", precision: 30, scale: 18
    t.index ["block_number"], name: "index_atoms_on_block_number"
    t.index ["creator_id"], name: "index_atoms_on_creator_id"
    t.index ["current_signal_value"], name: "index_atoms_on_current_signal_value"
    t.index ["did"], name: "index_atoms_on_did", unique: true
    t.index ["growth_24h_percent"], name: "index_atoms_on_growth_24h_percent"
    t.index ["growth_7d_percent"], name: "index_atoms_on_growth_7d_percent"
    t.index ["share_price"], name: "index_atoms_on_share_price"
    t.index ["type"], name: "index_atoms_on_type"
  end

  create_table "historical_signals", force: :cascade do |t|
    t.bigint "atom_id", null: false
    t.decimal "signal_value", precision: 20, scale: 8, default: "0.0"
    t.decimal "share_price", precision: 20, scale: 8, default: "0.0"
    t.datetime "recorded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["atom_id", "recorded_at"], name: "index_historical_signals_on_atom_id_and_recorded_at"
    t.index ["atom_id"], name: "index_historical_signals_on_atom_id"
    t.index ["recorded_at"], name: "index_historical_signals_on_recorded_at"
  end

  create_table "triples", force: :cascade do |t|
    t.string "triple_id", null: false
    t.string "subject_id", null: false
    t.string "predicate_id", null: false
    t.string "object_id", null: false
    t.string "vault_id"
    t.string "subject_label"
    t.string "predicate_label"
    t.string "object_label"
    t.decimal "total_deposited", precision: 30, scale: 18, default: "0.0"
    t.decimal "counter_deposited", precision: 30, scale: 18, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["object_id"], name: "index_triples_on_object_id"
    t.index ["predicate_id"], name: "index_triples_on_predicate_id"
    t.index ["subject_id", "predicate_id", "object_id"], name: "index_triples_on_spo"
    t.index ["subject_id"], name: "index_triples_on_subject_id"
    t.index ["triple_id"], name: "index_triples_on_triple_id", unique: true
    t.index ["vault_id"], name: "index_triples_on_vault_id"
  end

  add_foreign_key "historical_signals", "atoms"
end
