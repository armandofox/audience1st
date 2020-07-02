class Item < ActiveRecord::Base

  attr_protected :checked_in

  belongs_to :customer
  belongs_to :order
  belongs_to :account_code

  # BUG: not every Item subclass logically has a Vouchertype or Showdate, but the association is
  # needed at this level in order for the Accounting Report to avoid an n+1 query problem,
  # since it fetches a whole bunch of Item records and will dereference Vouchertype.
  belongs_to :vouchertype
  belongs_to :showdate

  validates_associated :order
  delegate :purchaser, :purchasemethod, :to => :order
  
  belongs_to :processed_by, :class_name => 'Customer'
  validates_presence_of :processed_by_id

  belongs_to :account_code
  validates_presence_of :account_code_id, :if => Proc.new { |a| a.amount > 0 }

  has_one :refunded_item, :foreign_key => 'bundle_id' # if item gets refunded

  def self.foreign_keys_to_customer
    [:customer_id, :processed_by_id]
  end

  def one_line_description ; raise "Must override this method" ; end
  def description_for_audit_txn ; raise "Must override this method" ; end

  # Finalizing an item means it is no longer part of an in-process order that isn't finalized yet
  def finalize! ; update_attributes!(:finalized => true) ; self; end
  scope :finalized, -> { where(:finalized => true) }

  # Canceling an item forces its price to zero and copies its original
  #  description into the comment field of the item

  def cancel!(by_whom)
    refund_item = RefundedItem.from_cancellation(self) if amount > 0
    self.comments = "[CANCELED #{by_whom.full_name} #{Time.current.to_formatted_s :long}] #{description_for_audit_txn}"
    self.type = 'CanceledItem'
    original_updated_at = self.updated_at.clone
    Item.transaction do
      refund_item.save! if refund_item
      self.save!
      # we have to explicitly do this to preserve updated_at.
      # Rails 5 would allow touch:false on save! to avoid updating :rails4:
      self.updated_at = original_updated_at
      self.save
    end
    CanceledItem.find(self.id)  #  !
  end

  def cancelable? ; true ; end
end
