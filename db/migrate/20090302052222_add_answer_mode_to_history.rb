class AddAnswerModeToHistory < ActiveRecord::Migration
  def self.up
    add_column :histories, :answer_mode, :integer   # 0: individual
                               # 1: book(training)
                               # 2: exam(test)
  end

  def self.down
    remove_column :histories, :answer_mode
  end
end
