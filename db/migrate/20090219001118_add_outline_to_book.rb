class AddOutlineToBook < ActiveRecord::Migration
  def self.up
    add_column :books, :outline, :text
  end

  def self.down
    remove_column :books, :outline, :text
  end
end
