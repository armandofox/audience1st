class RecurringDonationsController < ApplicationController

  before_action :is_logged_in
  before_action :get_customer_id

  def new
    @page_title = 'Set up new recurring donation'
    @account_codes = AccountCode.all
    @existing_recurring_donations = @customer.recurring_donations
    @recurring_donation = @customer.recurring_donations.build(
      :account_code => AccountCode.default_account_code,
      :amount => 50)
  end

  def show
    @recurring_donation = RecurringDonation.find params[:id]
  end

  def create
    recurring_donation_params = params.require(:recurring_donation).permit(:account_code_id, :amount)
    @recurring_donation = @customer.recurring_donations.build(recurring_donation_params)
    unless @recurring_donation.save
      return redirect_to(new_customer_recurring_donation_path(@customer),
                        :alert => @recurring_donation.errors.as_html)
    end
    # create the Stripe objects, and if all succeeds, redirect to a Stripe checkout session
    @recurring_donation.state = 'preparing'
    if @recurring_donation.prepare_checkout(callback_host)
      byebug
      redirect_to @recurring_donation.checkout_url, :status => 303
    else
      redirect_to new_customer_recurring_donations_path(@customer),
                  :alert => "Something went wrong: #{@recurring_donation.errors.as_html}"
    end
  end

  private

  def get_customer_id
    @customer = Customer.find params[:customer_id]
    # TBD check if admin is doing this, else enforce customer == logged in.  we may already
    # have a method to do this elsewhere
  end

end
