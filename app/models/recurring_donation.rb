class RecurringDonation < ActiveRecord::Base

  def self.default_code
    AccountCode.find(Option.default_donation_account_code)
  end

  belongs_to :account_code
  validates_associated :account_code
  validates_presence_of :account_code_id

  belongs_to :customer

  has_many :donations

  validates_numericality_of :amount
  validates_inclusion_of :amount, :in => 1..10_000_000, :message => "must be at least 1 dollar"

end
