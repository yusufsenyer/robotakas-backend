class AddSolutionAndReplyToForum < ActiveRecord::Migration[8.1]
  def change
    add_column :forum_topics, :solved_post_id, :integer
    add_column :forum_topics, :solved_at, :datetime

    add_column :forum_posts, :reply_to_post_id, :integer
    add_column :forum_posts, :reply_to_deleted, :boolean, default: false, null: false
  end
end
