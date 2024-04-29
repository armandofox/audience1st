class RecurringDonation < Item

  belongs_to :account_code
  belongs_to :customer
  has_many :donations, foreign_key: :recurring_donation_id

  def first_donation
    Donation.where(recurring_donation_id: id).order(sold_on: :asc).first
  end

  def monthly_amount
    donation = first_donation
    donation ? donation.amount : nil 
  end

  def total_amount_received
    Donation.where(recurring_donation_id: id).sum(:amount)
  end

  def one_line_description(opts={})
    if opts[:suppress_price]
      "Recurring Donation to #{account_code.name}"
    else
      sprintf("$%6.2f Recurring Donation to %s ($%6.2f received in total)", monthly_amount, account_code.name, total_amount_received)
    end
  end

  def description_for_audit_txn
    sprintf("%.2f %s recurring donation [%d]", monthly_amount, account_code.name, id)
  end
end
