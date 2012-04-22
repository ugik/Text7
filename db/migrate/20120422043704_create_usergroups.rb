class CreateUsergroups < ActiveRecord::Migration
  def change
    create_table :usergroups do |t|
      t.integer :user_id
      t.integer :group_id
      t.boolean :owner
      t.text :settings

      t.timestamps
    end
  end
end
