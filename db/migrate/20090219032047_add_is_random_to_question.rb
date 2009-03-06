class AddIsRandomToQuestion < ActiveRecord::Migration
  def self.up
    add_column :questions, :is_random, :boolean
  end

  def self.down
    remove_column :questions, :is_random
  end
end
