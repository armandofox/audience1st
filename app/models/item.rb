class Item < ActiveRecord::Base

  attr_protected :checked_in

  belongs_to :customer
  belongs_to :order
  validates_associated :order
  delegate :sold_on, :purchaser, :purchasemethod, :to => :order
  
  belongs_to :processed_by, :class_name => 'Customer'
  validates_presence_of :processed_by_id

  belongs_to :account_code
  validates_presence_of :account_code_id, :if => Proc.new { |a| a.amount > 0 }

  def self.foreign_keys_to_customer
    [:customer_id, :processed_by_id]
  end

  def one_line_description ; raise "Must override this method" ; end
  def description_for_audit_txn ; raise "Must override this method" ; end

  # Canceling an item forces its price to zero and copies its original
  #  description into the comment field of the item

  def cancel!(by_whom)
    self.comments = "[CANCELED #{by_whom.full_name} #{Time.current.to_formatted_s :long}] #{description_for_audit_txn}"
    self.type = 'CanceledItem'
    self.save!
    CanceledItem.find(self.id)  #  !
  end

  def cancelable? ; true ; end
end
