# to do:
#  add logic to init new donation with correct default account_code (from options)


class Donation < ActiveRecord::Base

  @@default_code = Option.value(:default_donation_account_code)

  belongs_to :donation_fund
  #belongs_to :purchasemethod
  belongs_to :customer
  has_one :processed_by, :class_name => 'Customer'
  validates_associated :donation_fund, :customer
  validates_numericality_of :amount
  validates_inclusion_of :amount, :in => 1..10_000_000, :message => "must be at least 1 dollar"

  # provide a handler to be called when customers are merged.
  # Transfers the donations from old to new id, and also changes the
  # values of processed_by field, which is really a customer id.
  # Returns number of actual donation records transferred.

  def self.additional_foreign_keys_to_customer
    [:processed_by_id]
  end

  def price ; self.amount ; end # why can't I use alias for this?

  def self.walkup_donation(amount,logged_in_id,purch=Purchasemethod.get_type_by_name('box_cash'))
    Donation.create(:date => Date.today,
                    :amount => amount,
                    :customer_id => Customer.walkup_customer.id,
                    :donation_fund_id => DonationFund.default_fund_id,
                    :purchasemethod_id => purch.id,
                    :account_code => @@default_code,
                    :letter_sent => false,
                    :processed_by_id => logged_in_id)
  end

  def self.online_donation(amount,cid,logged_in_id,purch=nil)
    purch ||= Purchasemethod.get_type_by_name('web_cc')
    Donation.new(:date => Time.now,
                 :amount => amount,
                 :customer_id => cid,
                 :donation_fund_id => DonationFund.default_fund_id,
                 :account_code => @@default_code,
                 :purchasemethod_id => purch.id,
                 :letter_sent => false,
                 :processed_by_id => logged_in_id)
  end
end
