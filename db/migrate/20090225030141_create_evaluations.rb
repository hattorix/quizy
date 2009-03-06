class CreateEvaluations < ActiveRecord::Migration
  def self.up
    create_table :evaluations do |t|
      t.column :question_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      t.column :point, :integer
      t.timestamps
    end
  end

  def self.down
    drop_table :evaluations
  end
end
