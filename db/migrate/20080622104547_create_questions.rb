class CreateQuestions < ActiveRecord::Migration
  def self.up
    create_table :questions do |t|
      # question
      t.column :question_type, :integer
      t.column :question_text, :text
      # for selection
      t.column :selections_count, :integer
      # scope
      t.column :is_public, :integer
      # foreign keys
      t.column :user_id, :integer
      t.column :category_id, :integer
      # create_at, update_at
      t.timestamps
    end
  end

  def self.down
    drop_table :questions
  end
end
