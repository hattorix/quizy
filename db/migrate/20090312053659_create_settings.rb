class CreateSettings < ActiveRecord::Migration
  def self.up
    create_table :settings do |t|
      t.column :user_id, :integer
      t.column :weak_line, :integer

      t.timestamps
    end
  end

  def self.down
    drop_table :settings
  end
end
