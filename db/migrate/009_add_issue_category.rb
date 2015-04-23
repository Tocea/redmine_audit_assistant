class AddIssueCategory < ActiveRecord::Migration
  def up
    add_column :requirements, :issue_category_name, :string
  end
  def down
    remove_column :requirements, :issue_category_name
  end
end
