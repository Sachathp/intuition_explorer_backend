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

ActiveRecord::Schema[8.0].define(version: 2025_12_16_092407) do
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
    t.decimal "market_cap", precision: 20, scale: 8, default: "0.0"
    t.decimal "positions_shares", precision: 20, scale: 8, default: "0.0"
    t.decimal "total_assets", precision: 20, scale: 8, default: "0.0"
    t.decimal "growth_1h_percent", precision: 10, scale: 4, default: "0.0"
    t.decimal "growth_4h_percent", precision: 10, scale: 4, default: "0.0"
    t.decimal "first_price_1h", precision: 30, scale: 18
    t.decimal "first_price_4h", precision: 30, scale: 18
    t.index ["block_number"], name: "index_atoms_on_block_number"
    t.index ["creator_id"], name: "index_atoms_on_creator_id"
    t.index ["current_signal_value"], name: "index_atoms_on_current_signal_value"
    t.index ["did"], name: "index_atoms_on_did", unique: true
    t.index ["growth_1h_percent"], name: "index_atoms_on_growth_1h_percent"
    t.index ["growth_24h_percent"], name: "index_atoms_on_growth_24h_percent"
    t.index ["growth_4h_percent"], name: "index_atoms_on_growth_4h_percent"
    t.index ["growth_7d_percent"], name: "index_atoms_on_growth_7d_percent"
    t.index ["market_cap"], name: "index_atoms_on_market_cap"
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

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
