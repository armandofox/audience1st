class RecurringDonation < Item

  belongs_to :account_code
  belongs_to :customer
  has_many :donations, foreign_key: :recurring_donation_id

  validates_associated :account_code
  validates_presence_of :account_code_id

  validates_numericality_of :amount
  validates_inclusion_of :amount, :in => 1..10_000_000, :message => "must be at least 1 dollar"

end
