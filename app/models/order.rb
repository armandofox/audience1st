class Order < ActiveRecord::Base
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

end
