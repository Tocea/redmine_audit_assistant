class CreateRequirements < ActiveRecord::Migration
  def change
    create_table :requirements do |t|
      t.string :name
      t.string :description
      t.float :charge
      t.string :category
      t.references :requirement, index:true
      #t.belongs_to :requirement, index:true
    end
  end
end
