class AddLabelToSpecialties < ActiveRecord::Migration[8.0]
  def change
    add_column :specialties, :label, :string
  end
end
