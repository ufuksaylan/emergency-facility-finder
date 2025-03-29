class CreateFacilityDetails < ActiveRecord::Migration[8.0]
  def change
    create_table :facility_details do |t|
      t.references :facility, null: false, foreign_key: true, index: { unique: true }

      t.boolean :dispensing, default: false

      t.integer :trauma_level, limit: 1

      t.boolean :appointment_required, default: false

      t.decimal :completeness_score, precision: 5, scale: 2
      t.datetime :last_updated

      t.timestamps
    end
  end
end
