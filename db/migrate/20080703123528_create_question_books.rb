class CreateQuestionBooks < ActiveRecord::Migration
  def self.up
    create_table :question_books do |t|
      t.column :book_id, :integer, :null => false
      t.column :question_id, :integer, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :question_books
  end
end
