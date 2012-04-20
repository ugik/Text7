class CreateTexts < ActiveRecord::Migration
  def self.up
    create_table :texts do |t|
      t.integer :user_id
      t.integer :group_id
      t.datetime :sent
      t.string :subject
      t.string :body
      t.text :settings

      t.timestamps
    end
    add_index :texts, :sent
  end

  def self.down
    drop_table :texts
  end
end

