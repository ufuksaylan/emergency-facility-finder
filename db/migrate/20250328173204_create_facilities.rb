class CreateFacilities < ActiveRecord::Migration[8.0]
  def change
    create_table :facilities do |t|
      t.bigint :osm_id, null: false
      t.string :name
      t.string :facility_type, null: false

      t.float :lat, null: false
      t.float :lng, null: false

      t.string :street
      t.string :house_number
      t.string :city, default: 'Vilnius'
      t.string :postcode

      t.text :opening_hours
      t.string :phone
      t.boolean :wheelchair_accessible, default: false

      t.boolean :has_emergency, default: false
      t.string :specialization

      t.timestamps
    end

    add_index :facilities, :osm_id, unique: true
    add_index :facilities, :facility_type
    add_index :facilities, :lat
    add_index :facilities, :lng
  end
end
