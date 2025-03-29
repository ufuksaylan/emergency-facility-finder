class CreateOsmMetadata < ActiveRecord::Migration[8.0]
  def change
    create_table :osm_metadata do |t|
      t.references :facility, null: false, foreign_key: true, index: { unique: true }
      t.bigint :changeset_id
      t.integer :changeset_version
      t.datetime :changeset_timestamp
      t.string :changeset_user

      t.timestamps
    end
  end
end
