class RefundedItem < Item
  belongs_to :account_code
  belongs_to :canceled_item, :foreign_key => 'bundle_id'
  validates_associated :canceled_item, :on => :create
  
  def shortdesc ; "[REFUND for item #{canceled_item.id}]" ; end
  def one_line_description(suppress_price: false); shortdesc; end
  def description_for_report ; shortdesc ; end
  def description_for_audit_txn ; shortdesc; end
  def item_description ; canceled_item.one_line_description ; end
  def comments ; '' ;  end
  def cancelable? ; false ; end

  def self.from_cancellation(orig_item)
    # orig_item is the item BEFORE being cancelled
    refund = RefundedItem.new
    fields_to_copy = orig_item.class.column_names - %w(id type created_at updated_at comments)
    fields_to_copy.each do |f|
      refund.send("#{f}=", orig_item.send(f))
    end
    refund.comments = "[REFUND for item #{orig_item.id}]"
    refund.bundle_id = orig_item.id
    # set price on the new item
    refund.amount = -(orig_item.amount)
    refund.sold_on = Time.current
    refund
  end
end

