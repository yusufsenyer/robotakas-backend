class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.string :reason, null: false
      t.text :details
      t.string :status, null: false, default: "open"
      t.references :resolved_by, null: true, foreign_key: { to_table: :users }
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :reports, :status
  end
end
