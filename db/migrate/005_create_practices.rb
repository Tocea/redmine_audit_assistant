class CreatePractices < ActiveRecord::Migration
  def change
    create_table :practices do |t|
      t.string :code
      t.string :name
      t.string :description
      t.belongs_to :goal, index:true
    end
  end
end
