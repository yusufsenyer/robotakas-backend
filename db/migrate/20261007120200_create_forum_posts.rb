class CreateForumPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :forum_posts do |t|
      t.references :forum_topic, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.datetime :edited_at

      t.timestamps
    end

    add_index :forum_posts, [ :forum_topic_id, :created_at ]
  end
end
