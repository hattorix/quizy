class AddNotesToExam < ActiveRecord::Migration
  def self.up
    add_column :exams, :notes, :text
  end

  def self.down
    remove_column :exams, :notes
  end
end
