class CreateSavedSearches < ActiveRecord::Migration[8.1]
  def change
    create_table :saved_searches do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.json :params, null: false, default: {}

      t.timestamps
    end

    add_index :saved_searches, [:user_id, :created_at]
  end
end
