class AddLocationPointToFacilities < ActiveRecord::Migration[8.0]
  def change
    add_column :facilities, :location, :st_point, geographic: true

    add_index :facilities, :location, using: :gist
  end
end
