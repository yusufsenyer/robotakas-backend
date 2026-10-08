class CreateForumTopics < ActiveRecord::Migration[8.1]
  def change
    create_table :forum_topics do |t|
      t.references :forum_board, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :title, null: false
      t.text :body, null: false
      t.boolean :pinned, default: false, null: false
      t.boolean :locked, default: false, null: false
      t.integer :posts_count, default: 0, null: false
      t.integer :views_count, default: 0, null: false
      t.datetime :last_activity_at
      t.datetime :edited_at
      t.string :slug

      t.timestamps
    end

    add_index :forum_topics, [:forum_board_id, :pinned, :last_activity_at]
  end
end
