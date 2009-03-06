class AddIsSmartAndTagsToBook < ActiveRecord::Migration
  def self.up
    add_column :books, :is_smart, :boolean
    add_column :books, :tags, :text
  end

  def self.down
    remove_column :books, :is_smart
    remove_column :books, :tags
  end
end
