class DeleteTimeLimitAndBorderLine < ActiveRecord::Migration
  def self.up
    remove_column :books, :time_limit
    remove_column :books, :border_line
  end

  def self.down
    add_column :books, :time_limit, :integer
    add_column :books, :border_line, :integer
  end
end
