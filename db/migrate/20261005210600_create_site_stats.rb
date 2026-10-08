class CreateSiteStats < ActiveRecord::Migration[8.1]
  def change
    create_table :site_stats do |t|
      t.string :key, null: false
      t.integer :value, null: false, default: 0, limit: 8

      t.timestamps
    end

    add_index :site_stats, :key, unique: true
  end
end
