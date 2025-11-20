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

ActiveRecord::Schema[8.0].define(version: 2025_11_20_135101) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "atoms", force: :cascade do |t|
    t.string "did", null: false
    t.text "description"
    t.decimal "current_signal_value", precision: 20, scale: 8, default: "0.0"
    t.decimal "share_price", precision: 20, scale: 8, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["current_signal_value"], name: "index_atoms_on_current_signal_value"
    t.index ["did"], name: "index_atoms_on_did", unique: true
    t.index ["share_price"], name: "index_atoms_on_share_price"
  end
end
