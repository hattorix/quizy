class AddColumnToQuestions < ActiveRecord::Migration
  def self.up
    add_column :questions, :question_count, :integer, :default => 0
    add_column :questions, :correct_count, :integer, :default => 0
    add_column :questions, :wrong_count, :integer, :default => 0
  end

  def self.down
    remove_column :questions, :question_count
    remove_column :questions, :correct_count
    remove_column :questions, :wrong_count
  end
end
