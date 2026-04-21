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

ActiveRecord::Schema[8.1].define(version: 2023_10_19_044650) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "forecasts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_temp", null: false, comment: "Current Temperature at the time of the request"
    t.integer "high_temp", null: false, comment: "Highes Temperature at the time of the request"
    t.integer "low_temp", null: false, comment: "Lowest Temperature at the time of the request"
    t.datetime "updated_at", null: false
    t.string "zip_code", limit: 10, null: false, comment: "ZIP Code with in mind for other countries than USA in future"
    t.index ["zip_code"], name: "index_forecasts_on_zip_code", unique: true
  end
end
