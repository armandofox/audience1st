class DonationFund < ActiveRecord::Base
  has_many :donations

  def self.default_fund_id
    DonationFund.find_by_id(1) ? 1 : DonationFund.find(:first)
  end
end
