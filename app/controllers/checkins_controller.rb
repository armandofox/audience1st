class CheckinsController < ApplicationController

  before_filter :is_boxoffice_filter

  # sets  instance variable @showdate and others for every method.
  before_filter :get_showdate, :except => [:update, :modify_walkup_vouchers]
  
  private

  # this filter must setup @showdates (pulldown menu) and @showdate
  # (current showdate, to which walkup sales will apply), or if not possible to set them,
  # force a redirect to a different controller & action
  def get_showdate
    @showdate = Showdate.find_by_id(params[:id])
    if @showdate.nil?
      # use default showdate, and redirect
      @showdate = Showdate.current_or_next(:grace_period => 2.hours)
      if @showdate.nil?
        flash[:alert] = "There are no shows this season eligible for check-in right now.  Please add some."
        return redirect_to(shows_path)
      else
        return redirect_to(params.to_hash.merge(:id => @showdate.id))
      end
    else
      year = Time.current.year
      @showdates = Showdate.all_showdates_for_seasons(year, year+1)
      @showdates << @showdate unless @showdates.include?(@showdate)
    end
    @page_title = "Will call: #{@showdate.thedate.to_formatted_s(:foh)}"
    if @showdate.has_reserved_seating?
      @seatmap_info = Seatmap.seatmap_and_unavailable_seats_as_json(@showdate)
    end
  end

  public

  def show
    @total,@vouchers = @showdate.grouped_vouchers
    if params[:cid]
      @customer = Customer.where(:id => Customer.id_from_route(params[:cid])).
        includes(:vouchers => {:vouchertype => :valid_vouchers}).
        first
      # which open vouchers are valid for this performance, and how many redemptions remaining?
      @customer_vouchers = @customer.vouchers.open.valid_for_showdate(@showdate)
    end
  end

  def walkup_subscriber_confirm
    return redirect_to(checkin_path(@showdate), :alert => "No vouchers were selected for check-in.") unless (@vouchers = params[:vouchers].try(:keys))
    begin
      Voucher.find(@vouchers).each do |v|
        v.reserve_for(@showdate, current_user)
        raise Voucher::ReservationError.new(v.errors.full_messages.join(', ')) unless v.errors.empty?
        v.check_in!
        @customer = v.customer
      end
    rescue ActiveRecord::RecordNotFound, StandardError => e
      raise e
      return redirect_to(checkin_path(@showdate), :alert => e.message)
    end
    checkins = @vouchers.count
    redirect_to checkin_path(@showdate), :notice => %Q{#{checkins} #{"checkin".pluralize(checkins)} confirmed for #{@customer.full_name}.}
  end

  def update
    render :nothing => true and return unless params[:vouchers]
    showdate = Showdate.find params[:id]
    ids = params[:vouchers].split(/,/)
    vouchers = ids.map { |v| Voucher.find_by_id(v) }.compact
    if params[:uncheck]
      vouchers.map { |v| v.un_check_in! }
      method = 'removeClass'
    else
      vouchers.map { |v| v.check_in! }
      method = 'addClass'
    end
    
    voucher_ids_for_js = ids.map { |id| "\##{id}" }.join(',')
    new_stats = ActionController::Base.helpers.escape_javascript(render_to_string :partial => 'show_stats', :locals => {:showdate => showdate}, :layout => false)
    script = %Q{
\$('#show_stats').html('#{new_stats}');
\$('#{voucher_ids_for_js}').#{method}('checked_in');
}
     render :js => script
  end

  def seatmap
    # @seatmap_info has already been setup
    @page_title = 'Seat map'
    sold = @showdate.finalized_vouchers.size
    cap = @showdate.house_capacity
    available = [0, cap-sold].max
    @seats_available = "#{@showdate.printable_name}: #{available} of #{cap} seats available"
    render :layout => 'door_list'
  end
  
  def door_list
    @page_title = 'Door list'
    @total,@vouchers = @showdate.grouped_vouchers
    @num_subscriber_reservations = @vouchers.values.flatten.count { |v| v.vouchertype.subscriber_voucher? }
    if @vouchers.empty?
      flash[:notice] = "No reservations for '#{@showdate.printable_name}'"
      redirect_to walkup_sale_path(@showdate)
    else
      render :layout => 'door_list'
    end
  end

end
