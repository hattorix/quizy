class AddCategoriesToBook < ActiveRecord::Migration
  def self.up
    add_column :books, :categories, :text
  end

  def self.down
    remove_column :books, :categories
  end
end
