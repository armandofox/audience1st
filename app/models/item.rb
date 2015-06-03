class Item < ActiveRecord::Base
  acts_as_reportable
  
  belongs_to :customer
  belongs_to :order
  validates_associated :order
  
  belongs_to :processed_by, :class_name => 'Customer'
  validates_presence_of :processed_by_id

  delegate :sold_on, :purchasemethod, :to => :order

  def self.foreign_keys_to_customer
    [:customer_id, :processed_by_id]
  end

end
