class CreateMyBooks < ActiveRecord::Migration
  def self.up
    create_table :my_books do |t|
      t.column :user_id, :integer, :null => false
      t.column :book_id, :integer, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :my_books
  end
end
