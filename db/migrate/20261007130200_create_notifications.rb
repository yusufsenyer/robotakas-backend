class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :kind, null: false
      t.integer :forum_topic_id
      t.integer :forum_post_id
      t.integer :count, default: 1, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [ :user_id, :read_at ]
    add_index :notifications, [ :user_id, :kind, :forum_topic_id, :forum_post_id ],
      name: "index_notifications_on_dedupe"
  end
end
