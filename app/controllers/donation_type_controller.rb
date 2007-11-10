class DonationTypeController < ApplicationController

  before_filter :is_staff_filter
  scaffold :donation_type

end
