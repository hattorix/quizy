class CreateReports < ActiveRecord::Migration
  def self.up
    create_table :reports do |t|
      t.column :user_id, :integer, :null => false
      t.column :question_id, :integer, :null => false
      t.column :description, :text
      t.timestamps
    end
  end

  def self.down
    drop_table :reports
  end
end
