class CreateFacilitySpecialties < ActiveRecord::Migration[8.0]
  def change
    create_table :facility_specialties do |t|
      t.references :facility, null: false, foreign_key: true
      t.references :specialty, null: false, foreign_key: true

      t.timestamps
    end
  end
end
