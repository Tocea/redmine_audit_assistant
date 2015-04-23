class AddPriority < ActiveRecord::Migration
  def up
    add_column :requirements, :priority_id, :integer
  end
  def down
    remove_column :requirements, :priority_id
  end
end
