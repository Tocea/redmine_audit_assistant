class CreateGoals < ActiveRecord::Migration
  def change
    create_table :goals do |t|
      t.string :code
      t.string :name
      t.string :description
      t.belongs_to :domain, index:true
    end
  end
end
