class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements do |t|
      t.references :admin, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :body, null: false
      t.datetime :published_at

      t.timestamps
    end

    add_index :announcements, :published_at
  end
end
