class CreateSettings < ActiveRecord::Migration
  def self.up
    create_table :settings do |t|
      t.column :user_id, :integer
      t.column :weak_lv_1, :integer
      t.column :weak_lv_2, :integer
      t.column :weak_lv_3, :integer
      t.column :weak_lv_4, :integer
      t.column :weak_lv_5, :integer

      t.timestamps
    end
  end

  def self.down
    drop_table :settings
  end
end
