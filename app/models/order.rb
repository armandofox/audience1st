class Order < ActiveRecord::Base
  belongs_to :customer
  belongs_to :purchasemethod
  has_many :items

  validates_presence_of :sold_on
  validates_presence_of :processed_by_id
  validates_presence_of :purchasemethod_id
  validates_presence_of :customer_id

  attr_reader :cart_items

  def initialize
    @cart_items = []
    super
  end

  def empty_cart! ;  @cart_items = [] ;             end
  
  def add_item(item) ;  @cart_items << item ;       end

  def total_price ;     @cart_items.sum(&:amount) ; end

  def purchased? ;    !sold_on.blank? ; end

  def cart_vouchers ; @cart_items.select { |i| i.kind_of? Voucher } ; end
  def cart_donations ;@cart_items.select { |i| i.kind_of? Donation } ; end

  def add_comment(comment)
    cart_vouchers.each { |v| v.add_comment comment }
  end
  
  def refundable_to_credit_card?
    purchased? && purchasemethod.purchase_medium == :credit_card  && !authorization.blank?
  end

end
