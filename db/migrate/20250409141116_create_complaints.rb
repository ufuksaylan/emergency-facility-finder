class CreateComplaints < ActiveRecord::Migration[8.0]
  def change
    create_table :complaints do |t|
      t.references :facility, null: false, foreign_key: true, index: true
      t.text :description, null: false
      t.string :status, null: false, default: 'submitted', index: true
      t.text :resolution_notes
      t.datetime :resolved_at
      t.timestamps
    end
  end
end
