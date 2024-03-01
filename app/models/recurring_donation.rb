class RecurringDonation < ActiveRecord::Base

  belongs_to :account_code
  belongs_to :customer
  has_many :donations

  def self.from_order_w_first_donation_and_save(order)
    @recurring_donation = RecurringDonation.create!(
      account_code_id: order.donation.account_code_id,
      customer_id: order.customer_id,
      amount: order.donation.amount,
      comments: order.donation.comments)
    @recurring_donation
  end

end
