class CreateForumBoards < ActiveRecord::Migration[8.1]
  def change
    create_table :forum_boards do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :description
      t.string :icon_key
      t.string :kind, null: false
      t.integer :position, default: 0, null: false
      t.integer :topics_count, default: 0, null: false
      t.integer :posts_count, default: 0, null: false
      t.datetime :last_activity_at

      t.timestamps
    end

    add_index :forum_boards, :slug, unique: true
  end
end
