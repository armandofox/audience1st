class CreateGroup < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name
      t.timestamps
    end

    create_table :customers_groups, id: false do |t|
      t.belongs_to :customer, index: true
      t.belongs_to :group, index: true
    end
  end
end