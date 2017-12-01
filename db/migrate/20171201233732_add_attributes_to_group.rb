class AddAttributesToGroup < ActiveRecord::Migration
  def change
    add_column :groups, :address_line_1, :string
    add_column :groups, :address_line_2, :string
    add_column :groups, :city, :string
    add_column :groups, :state, :string
    add_column :groups, :zip, :string
    add_column :groups, :work_phone, :string
    add_column :groups, :cell_phone, :string
    add_column :groups, :work_fax, :string
    add_column :groups, :group_url, :string
    add_column :groups, :best_way_to_contact, :string
  end
end
