class Order < ActiveRecord::Base
  acts_as_reportable
  
  belongs_to :customer
  belongs_to :purchasemethod
  has_many :items

  validates_presence_of :sold_on
  validates_presence_of :processed_by_id
  validates_presence_of :purchasemethod_id
  validates_presence_of :customer_id

  def refundable_to_credit_card?
    purchasemethod.purchase_medium == :credit_card  && !authorization.blank?
  end

  def total
    # :BUG: 79120088: this should be replaceable by 
    #    items.sum(:amount)
    # when every Item's 'amount' field is correctly filled in at order time
    items.map(&:amount).sum
  end
  
  def purchasemethod_description
    purchasemethod.description
  end

end
