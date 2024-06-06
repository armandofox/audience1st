class RecurringDonationsController < ApplicationController

  before_action :is_logged_in
  before_action :get_customer_id

  def new
    @account_codes = AccountCode.all
    @recurring_donation = @customer.recurring_donations.build(
      :account_code => AccountCode.default_account_code,
      :amount => 50,
      :state => :building)
  end

  private

  def get_customer_id
    @customer = Customer.find params[:customer_id]
    # TBD check if admin is doing this, else enforce customer == logged in.  we may already
    # have a method to do this elsewhere
  end

end
