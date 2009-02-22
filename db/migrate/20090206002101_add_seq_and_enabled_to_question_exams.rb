class AddSeqAndEnabledToQuestionExams < ActiveRecord::Migration
  def self.up
    add_column :question_exams, :seq, :integer
    add_column :question_exams, :enabled, :boolean
  end

  def self.down
    remove_column :question_exams, :enabled
    remove_column :question_exams, :seq
  end
end
