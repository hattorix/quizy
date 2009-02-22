class CreateDescriptions < ActiveRecord::Migration
  def self.up
    create_table :descriptions do |t|
      t.text :description_text
      t.integer :question_id
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :descriptions
  end
end
