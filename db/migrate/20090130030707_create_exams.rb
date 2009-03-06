class CreateExams < ActiveRecord::Migration
  def self.up
    create_table :exams do |t|
      t.string :name
      t.integer :questions_count
      t.integer :time_limit
      t.integer :border_line
      t.integer :is_public
      t.integer :user_id
      t.integer :book_id

      t.timestamps
    end
  end

  def self.down
    drop_table :exams
  end
end
