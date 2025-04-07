class AddContactAndStatusToFacilities < ActiveRecord::Migration[8.0]
  def change
    add_column :facilities, :website, :string
    add_column :facilities, :email, :string
  end
end
