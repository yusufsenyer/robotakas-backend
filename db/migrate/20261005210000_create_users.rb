class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :full_name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :city, null: false
      t.string :team_name
      t.string :phone
      t.string :role, null: false, default: "user"

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
