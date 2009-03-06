class CreateExamTemps < ActiveRecord::Migration
  def self.up
    create_table :exam_temps do |t|
      t.integer :exam_id
      t.integer :question_id
      t.string :answer
      t.string :status
      t.boolean :t_or_f
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :exam_temps
  end
end
