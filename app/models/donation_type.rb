class DonationType < ActiveRecord::Base
  has_many :donations

  def self.cash_donation_id
    DonationType.find_by_name("Cash")
  end
end
