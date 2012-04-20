class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :cell
      t.text :settings

      t.timestamps
    end
    add_index :users, :cell
  end

  def self.down
    drop_table :users
  end

end
