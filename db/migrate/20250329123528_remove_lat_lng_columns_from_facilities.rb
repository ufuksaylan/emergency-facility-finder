class RemoveLatLngColumnsFromFacilities < ActiveRecord::Migration[8.0]
  def up
    remove_index :facilities, :lat
    remove_index :facilities, :lng

    remove_column :facilities, :lat
    remove_column :facilities, :lng
  end
end
