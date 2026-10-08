class CreateListingCompatibleCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :listing_compatible_categories do |t|
      t.references :listing, foreign_key: true, null: false
      t.references :category, foreign_key: true, null: false

      t.timestamps
    end

    add_index :listing_compatible_categories,
      [:listing_id, :category_id],
      unique: true,
      name: "index_lcc_on_listing_and_category"
  end
end
