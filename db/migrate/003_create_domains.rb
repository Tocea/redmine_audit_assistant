class CreateDomains < ActiveRecord::Migration
  def change
    create_table :domains do |t|
      t.string :code
      t.string :name
      t.string :description
      t.belongs_to :category, index:true
    end
  end
end
