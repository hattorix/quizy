class AddWeakLineToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :weak_line, :integer

  end

  def self.down
    remove_column :users, :weak_line
  end
end
