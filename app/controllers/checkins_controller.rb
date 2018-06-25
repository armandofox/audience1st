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
        redirect_to shows_path
      else
        redirect_to params.to_hash.merge(:id => @showdate.id)
      end
    else
      year = Time.now.year
      @showdates = Showdate.all_showdates_for_seasons(year, year+1)
      @showdates << @showdate unless @showdates.include?(@showdate)
    end
  end

  def vouchers_for_showdate(showdate)
    perf_vouchers = @showdate.advance_sales_vouchers
    total = perf_vouchers.size
    num_subscribers = perf_vouchers.select { |v| v.customer.subscriber? }.size
    vouchers = perf_vouchers.group_by do |v|
      "#{v.customer.last_name},#{v.customer.first_name},#{v.customer_id},#{v.vouchertype_id}"
    end
    return [total,num_subscribers,vouchers]
  end

  public

  def show
    @total,@num_subscribers,@vouchers = vouchers_for_showdate(@showdate)
  end

  def walkup_subscriber
    if params[:cid]
      @customer = Customer.where(:id => Customer.id_from_route(params[:cid])).
        includes(:vouchers => {:vouchertype => :valid_vouchers})
        .first
      # which open vouchers are valid for this performance?
      @vouchers = @customer.vouchers.open.map do |v|
        if (qty = v.redeemable_for?(@showdate)) then [v,qty] else nil end
      end.compact
    end
  end

  def walkup_subscriber_confirm
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

  def door_list
    @total,@num_subscribers,@vouchers = vouchers_for_showdate(@showdate)
    if @vouchers.empty?
      flash[:notice] = "No reservations for '#{@showdate.printable_name}'"
      redirect_to walkup_sale_path(@showdate)
    else
      render :layout => false
    end
  end

end
