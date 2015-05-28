class CreateIssueStatusActions < ActiveRecord::Migration
  def change
    create_table :issue_status_actions do |t|
      t.string :lib
      t.integer :status_id_from
      t.integer :status_id_to
    end
  end
end
