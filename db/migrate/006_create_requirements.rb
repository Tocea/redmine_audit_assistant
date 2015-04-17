class CreateRequirements < ActiveRecord::Migration
  def change
    if ActiveRecord::Base.connection.table_exists? :requirements
      drop_table :requirements
    end
    create_table :requirements do |t|
      t.string :name
      t.string :description
      t.float :charge
      t.string :category
      t.date :start_date
      t.date :effective_date
      t.references :requirement, index:true
      #t.belongs_to :requirement, index:true
    end
  end
end