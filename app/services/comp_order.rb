class CompOrder

  include ActiveModel::Model

  attr_accessor :howmany, :vouchertype_id, :showdate_id, :customer, :seats, :comments, :processed_by
  attr_reader :order, :showdate, :vouchertype
  attr_reader :confirmation_message
  
  validates_presence_of :howmany
  validates_numericality_of :howmany, :greater_than => 0, :only_integer => true
  validate :vouchertype_exists?
  validate :valid_for_performance?, :unless => ->{ showdate_id.blank? }

  def leave_open? ; showdate_id.blank? ; end
  
  def finalize
    order_params = { :comments => comments, :processed_by => processed_by,
      :purchasemethod => Purchasemethod.get_type_by_name('none') }
    begin
      @order = Order.create!(order_params)
      @order.customer = @order.purchaser = customer
      if leave_open?
        @order.add_open_vouchers_without_capacity_checks(@vouchertype, howmany.to_i)
        @confirmation_message = "Added #{howmany} '#{@vouchertype.name}' comps and customer can choose the show later."
      else
        @order.add_tickets_without_capacity_checks(@vv, howmany.to_i, seats)
        @confirmation_message = "Added #{howmany} '#{@vv.name}' comps for #{@vv.showdate.printable_name}."
      end
      @order.finalize!
      true
    rescue Order::NotReadyError => e
      errors.add(:base, "Could not confirm comp order: #{e.message}")
      nil
    end
  end

  private

  def vouchertype_exists?
    unless (@vouchertype = Vouchertype.find_by(:id => vouchertype_id))
      errors.add(:base, "Please specify a valid voucher type.")
    end
  end
  def valid_for_performance?
    errors.add(:showdate_id, "is invalid") and return unless @showdate = Showdate.find_by(:id => showdate_id)
    errors.add(:vouchertype_id, "is not valid for the selected performance") unless (@vv = ValidVoucher.find_by(:showdate_id => showdate_id, :vouchertype_id => vouchertype_id))
  end

end
