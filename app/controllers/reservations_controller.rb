class ReservationsController < ApplicationController

  before_action :is_logged_in

  # AJAX helper for adding comps

  def update_shows
    @valid_vouchers = ValidVoucher.
      where(:vouchertype_id => params[:vouchertype_id]).
      includes(:showdate => :show).
      order('showdates.thedate')
    render :partial => 'vouchers/reserve_comps_for'
  end

end
