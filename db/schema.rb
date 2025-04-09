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

ActiveRecord::Schema[8.0].define(version: 2025_04_09_074819) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"

  create_table "facilities", force: :cascade do |t|
    t.bigint "osm_id", null: false
    t.string "name"
    t.string "facility_type", null: false
    t.string "street"
    t.string "house_number"
    t.string "city", default: "Vilnius"
    t.string "postcode"
    t.text "opening_hours"
    t.string "phone"
    t.boolean "wheelchair_accessible", default: false
    t.boolean "has_emergency", default: false
    t.string "specialization"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.geography "location", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.string "website"
    t.string "email"
    t.index ["facility_type"], name: "index_facilities_on_facility_type"
    t.index ["location"], name: "index_facilities_on_location", using: :gist
    t.index ["osm_id"], name: "index_facilities_on_osm_id", unique: true
  end

  create_table "facility_details", force: :cascade do |t|
    t.bigint "facility_id", null: false
    t.boolean "dispensing", default: false
    t.integer "trauma_level", limit: 2
    t.boolean "appointment_required", default: false
    t.decimal "completeness_score", precision: 5, scale: 2
    t.datetime "last_updated"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["facility_id"], name: "index_facility_details_on_facility_id", unique: true
  end

  create_table "facility_specialties", force: :cascade do |t|
    t.bigint "facility_id", null: false
    t.bigint "specialty_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["facility_id"], name: "index_facility_specialties_on_facility_id"
    t.index ["specialty_id"], name: "index_facility_specialties_on_specialty_id"
  end

  create_table "osm_metadata", force: :cascade do |t|
    t.bigint "facility_id", null: false
    t.bigint "changeset_id"
    t.integer "changeset_version"
    t.datetime "changeset_timestamp"
    t.string "changeset_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["facility_id"], name: "index_osm_metadata_on_facility_id", unique: true
  end

  create_table "specialties", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "label"
    t.index ["name"], name: "index_specialties_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email"
  end

  add_foreign_key "facility_details", "facilities"
  add_foreign_key "facility_specialties", "facilities"
  add_foreign_key "facility_specialties", "specialties"
  add_foreign_key "osm_metadata", "facilities"
end
