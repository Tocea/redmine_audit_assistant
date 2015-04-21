class AddChecklist < ActiveRecord::Migration
  def up
    add_column :requirements, :checklist, :text
  end
  def down
    remove_column :requirements, :checklist
  end
end
