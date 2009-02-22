class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
      t.column :name, :string, :limit => 64
      t.column :user_id, :integer
      t.timestamps
    end
  end

  def self.down
    drop_table :categories
  end
end
