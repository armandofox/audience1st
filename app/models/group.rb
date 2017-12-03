class Group < ActiveRecord::Base

  attr_accessible :name, :address_line_1, :address_line_2, :city, :state, :zip, :work_phone, :cell_phone, :work_fax, :group_url, :comments, :type
  has_and_belongs_to_many :customers
  self.inheritance_column = :type

end
