class CreateMyExams < ActiveRecord::Migration
  def self.up
    create_table :my_exams do |t|
      t.column :user_id, :integer, :null => false
      t.column :exam_id, :integer, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :my_exams
  end
end
