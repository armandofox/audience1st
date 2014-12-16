class Item < ActiveRecord::Base

  belongs_to :customer
  belongs_to :order
  validates_associated :order
  
  belongs_to :purchasemethod
  validates_presence_of :purchasemethod_id

  belongs_to :processed_by, :class_name => 'Customer'
  validates_presence_of :processed_by_id
  

end
