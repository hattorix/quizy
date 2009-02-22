class CreateQuestionExams < ActiveRecord::Migration
  def self.up
    create_table :question_exams do |t|
      t.column :exam_id, :integer, :null => false
      t.column :question_id, :integer, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :question_exams
  end
end
