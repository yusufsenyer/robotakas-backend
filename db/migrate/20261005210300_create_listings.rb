class CreateListings < ActiveRecord::Migration[8.1]
  def change
    create_table :listings do |t|
      t.references :user, foreign_key: true, null: false
      t.references :category, foreign_key: true, null: false
      t.references :part, foreign_key: true, null: true
      t.string :title, null: false
      t.text :description, null: false
      t.string :condition, null: false
      t.integer :price, null: false
      t.integer :quantity, null: false, default: 1
      t.integer :seasons_used
      t.string :city, null: false
      t.string :district
      t.boolean :show_phone, null: false, default: false
      t.string :status, null: false, default: "active"
      t.string :removal_reason
      t.datetime :removed_at
      t.datetime :published_at
      t.integer :view_count, null: false, default: 0

      t.timestamps
    end

    add_index :listings, :status
    add_index :listings, :published_at
  end
end
