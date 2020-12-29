class CheckinsController < ApplicationController

  before_filter :is_boxoffice_filter

  # sets  instance variable @showdate and others for every method.
  before_filter :get_showdate, :except => [:update, :modify_walkup_vouchers]
  
  private

  # this filter must setup @showdates (pulldown menu) and @showdate
  # (current showdate, to which walkup sales will apply), or if not possible to set them,
  # force a redirect to a different controller & action
  def get_showdate
    if (@showdate = Showdate.in_theater.find_by(:id => params[:id]))
      @showdates = Showdate.in_theater.all_showdates_for_seasons(Time.current.year, Time.current.year+1)
      @showdates << @showdate unless @showdates.include?(@showdate)
      @page_title = "Will call: #{@showdate.thedate.to_formatted_s(:foh)}"
      @seatmap_info = Seatmap.seatmap_and_unavailable_seats_as_json(@showdate) if @showdate.has_reserved_seating?
      return
    end
    # nil showdate: try defaulting to current or next
    if (@showdate = Showdate.in_theater.current_or_next(:grace_period => 2.hours))
      redirect_to(params.to_hash.merge(:id => @showdate.id))
    else
      redirect_to(shows_path, :alert => I18n.t('checkins.no_showdates'))
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
        raise ReservationError.new(v.errors.full_messages.join(', ')) unless v.errors.empty?
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
\$('#{voucher_ids_for_js}').#{method}('a1-checked-in');
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
