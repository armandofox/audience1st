class RecurringDonation < Item

  belongs_to :account_code
  belongs_to :customer
  has_many :donations, foreign_key: :recurring_donation_id

  def one_line_description ; end
  def description_for_audit_txn ; end
end
