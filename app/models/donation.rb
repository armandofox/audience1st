class Donation < ActiveRecord::Base
  belongs_to :donation_type
  belongs_to :donation_fund
  #belongs_to :purchasemethod
  belongs_to :customer
  validates_associated :donation_type, :donation_fund, :customer
  validates_numericality_of :amount
  validates_inclusion_of :amount, :in => 1..10_000_000, :message => "must be at least 1 dollar"

  def price ; self.amount ; end # why can't I use alias for this?

  def self.walkup_donation(amount,logged_in_id,purch=Purchasemethod.get_type_by_name('box_cash'))
    Donation.create(:date => Date.today,
                    :amount => amount,
                    :customer_id => Customer.walkup_customer.id,
                    :donation_fund_id => DonationFund.default_fund_id,
                    :donation_type_id => DonationType.cash_donation_id,
                    :purchasemethod_id => purch.id,
                    :letter_sent => false,
                    :processed_by => logged_in_id)
  end

  def self.online_donation(amount,cid,logged_in_id,purch=nil)
    unless purch
      purch = Purchasemethod.get_type_by_name(cid == logged_in_id ? 'cust_web' :
                                              'box_credit')
    end
    Donation.new(:date => Time.now,
                 :amount => amount,
                 :customer_id => cid,
                 :donation_fund_id => DonationFund.default_fund_id,
                 :donation_type_id => DonationType.cash_donation_id,
                 :purchasemethod_id => purch.id,
                 :letter_sent => false,
                 :processed_by => logged_in_id)
  end
end
