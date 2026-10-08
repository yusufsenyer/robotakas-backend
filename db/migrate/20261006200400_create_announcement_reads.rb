class CreateAnnouncementReads < ActiveRecord::Migration[8.1]
  def change
    create_table :announcement_reads do |t|
      t.references :user, null: false, foreign_key: true
      t.references :announcement, null: false, foreign_key: true

      t.timestamps
    end

    add_index :announcement_reads, [:user_id, :announcement_id], unique: true
  end
end
