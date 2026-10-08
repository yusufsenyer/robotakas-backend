class CreateForumLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :forum_likes do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :forum_topic_id
      t.integer :forum_post_id
      t.datetime :created_at, null: false
    end

    add_index :forum_likes, [ :user_id, :forum_topic_id ],
      unique: true, where: "forum_topic_id IS NOT NULL"
    add_index :forum_likes, [ :user_id, :forum_post_id ],
      unique: true, where: "forum_post_id IS NOT NULL"
    add_index :forum_likes, :forum_post_id

    add_column :forum_topics, :likes_count, :integer, default: 0, null: false
    add_column :forum_posts, :likes_count, :integer, default: 0, null: false
  end
end
