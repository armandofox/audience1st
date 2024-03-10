class RecurringDonation < Item

  belongs_to :account_code
  belongs_to :customer
  has_many :donations, foreign_key: :recurring_donation_id

  validates_associated :account_code
  validates_presence_of :account_code_id

  def self.from_account_code(account_code)
    RecurringDonation.new(:amount => 0, :account_code => account_code)
  end

  def one_line_description ; end
  def description_for_audit_txn ; end
end
