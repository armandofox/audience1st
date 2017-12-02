class Group < ActiveRecord::Base
  has_and_belongs_to_many :customers
  self.inheritance_column = :type

end
