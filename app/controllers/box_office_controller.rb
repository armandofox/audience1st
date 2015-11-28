class BoxOfficeController < ApplicationController

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
        redirect_to params.merge(:id => @showdate)
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

  def index
    @total,@num_subscribers,@vouchers = vouchers_for_showdate(@showdate)
  end

  def update
    render :nothing => true and return unless params[:vouchers]
    vouchers = params[:vouchers].split(/,/).map { |v| Voucher.find_by_id(v) }.compact
    if params[:uncheck]
      vouchers.map { |v| v.un_check_in! }
    else
      vouchers.map { |v| v.check_in! }
    end
    render :update do |page|
      showdate = vouchers.first.showdate
      page.replace_html 'show_stats', :partial => 'show_stats', :locals => {:showdate => showdate}
      if params[:uncheck]
        vouchers.each { |v| page[v.id.to_s].removeClassName('checked_in') }
      else
        vouchers.each { |v| page[v.id.to_s].addClassName('checked_in') }
      end
    end
  end

  def door_list
    @total,@num_subscribers,@vouchers = vouchers_for_showdate(@showdate)
    if @vouchers.empty?
      flash[:notice] = "No reservations for '#{@showdate.printable_name}'"
      redirect_to box_office_path(@showdate)
    else
      render :layout => 'door_list'
    end
  end

  def walkup_report
    @vouchers = @showdate.walkup_vouchers.group_by(&:purchasemethod)
    @subtotal = {}
    @total = 0
    @vouchers.each_pair do |purch,vouchers|
      @subtotal[purch] = vouchers.map(&:amount).sum
      @total += @subtotal[purch]
    end
    @other_showdates = @showdate.show.showdates
  end


end
