class DonationFundController < ApplicationController

  before_filter :is_staff_filter
  scaffold :donation_fund
  
end
