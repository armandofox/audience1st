# to do:
#  add logic to init new donation with correct default account_code (from options)


class Donation < ActiveRecord::Base

  @@default_code = Option.value(:default_donation_account_code)

  belongs_to :account_code
  validates_associated :account_code
  validates_presence_of :account_code_id
  
  belongs_to :purchasemethod
  validates_presence_of :purchasemethod_id
  
  belongs_to :customer
  validates_associated :customer
  
  has_one :processed_by, :class_name => 'Customer'

  validates_numericality_of :amount
  validates_presence_of :date
  validates_inclusion_of :amount, :in => 1..10_000_000, :message => "must be at least 1 dollar"

  def self.foreign_keys_to_customer
    [:customer_id, :processed_by_id]
  end

  def price ; self.amount ; end # why can't I use alias for this?

  def self.walkup_donation(amount,logged_in_id,purch=Purchasemethod.get_type_by_name('box_cash'))
    Donation.create(:date => Date.today,
                    :amount => amount,
                    :customer_id => Customer.walkup_customer.id,
                    :account_code_id => AccountCode.default_account_code_id,
                    :purchasemethod_id => purch.id,
                    :account_code => @@default_code,
                    :letter_sent => false,
                    :processed_by_id => logged_in_id)
  end

  def self.online_donation(amount,cid,logged_in_id,purch=Purchasemethod.get_type_by_name('web_cc'))
    Donation.new(:date => Time.now,
                 :amount => amount,
                 :customer_id => cid,
                 :account_code_id => AccountCode.default_account_code_id,
                 :account_code => @@default_code,
                 :purchasemethod_id => purch.id,
                 :letter_sent => false,
                 :processed_by_id => logged_in_id)
  end
end
