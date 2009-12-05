class DonationFund < ActiveRecord::Base
  has_many :donations

  def self.default_fund_id
    self.default_fund.id
  end
  
  def self.default_fund
    DonationFund.find(:first) ||
      DonationFund.create!(:name => "General Fund",
      :description => "General Fund")
  end

  # convenience accessor

  def fund_with_account_code
    self.account_code.blank? ? self.name : "#{self.name} (#{self.account_code})"
  end
end
