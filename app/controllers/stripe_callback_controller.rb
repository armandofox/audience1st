class StripeCallbackController < ApplicationController

  # These should 
  # Successful initiation of a recurring donation 
  def recurring_donation_success
    id = params.require(:id)
    recurring_donation = RecurringDonation.find(id)
    redirect_to customer_path(recurring_donation.customer), :notice => 'Thank you for setting up a monthly donation! This message will be customizable by the theater.'
  end

  # Unsuccessful attempt to initiate recurring donation
  def recurring_donation_failure
    byebug
  end

end
