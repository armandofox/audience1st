class Donation < ActiveRecord::Base
  belongs_to :donation_type
  belongs_to :donation_fund
  belongs_to :customer
  validates_associated :donation_type, :donation_fund, :customer
  validates_numericality_of :amount
  validates_inclusion_of :amount, :in => 1..10_000_000, :message => "must be at least 1 dollar"
  def price ; self.amount ; end # why can't I use alias for this?
end
