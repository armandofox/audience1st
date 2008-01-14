class CreateOptions < ActiveRecord::Migration
  def self.up
    create_table :options, :force => true do |t|
      t.column :grp, :string
      t.column :name, :string
      t.column :value, :string, :null => false
      t.column :description, :text
      t.column :typ, :enum, :limit => [:int,:string,:email,:float], :null => false, :default => :string
    end
  end

  def self.down
    drop_table :options
  end
end
