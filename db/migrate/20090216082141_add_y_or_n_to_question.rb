class AddYOrNToQuestion < ActiveRecord::Migration
  def self.up
    add_column :questions, :y_or_n, :boolean
  end

  def self.down
    remove_column :questions, :y_or_n, :boolean
  end
end
