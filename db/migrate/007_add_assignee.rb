class AddAssignee < ActiveRecord::Migration
  def up
    add_column :requirements, :assignee_login, :string
  end
  def down
    remove_column :requirements, :assignee_login
  end
end
