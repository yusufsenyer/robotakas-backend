class CreateParts < ActiveRecord::Migration[8.1]
  def change
    create_table :parts do |t|
      t.string :code, null: false
      t.string :slug, null: false
      t.string :name, null: false
      t.string :brand
      t.references :category, foreign_key: true, null: false
      t.text :description
      t.json :specs, null: false, default: []
      t.string :status, null: false, default: "pending"
      t.references :suggested_by, foreign_key: { to_table: :users }, null: true
      t.string :reject_reason

      t.timestamps
    end

    add_index :parts, :code, unique: true
    add_index :parts, :slug, unique: true
    add_index :parts, :status
  end
end
