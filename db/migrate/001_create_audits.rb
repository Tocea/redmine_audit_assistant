class CreateAudits < ActiveRecord::Migration
  def change
    create_table :audits do |t|
      t.string :name
      t.string :version
    end
  end
end
