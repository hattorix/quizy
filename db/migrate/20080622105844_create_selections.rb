class CreateSelections < ActiveRecord::Migration
  def self.up
    create_table :selections do |t|
      t.column :selection_text, :text
      t.column :is_collect, :integer
      t.column :question_id, :integer
      t.column :user_id, :integer
      t.timestamps
    end
  end

  def self.down
    drop_table :selections
  end
end
