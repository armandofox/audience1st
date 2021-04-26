class ValidVouchersController < ApplicationController

  before_filter :is_boxoffice_filter
  before_filter(:is_boxoffice_manager_filter,:except => :show)

  def show
    @valid_voucher = ValidVoucher.find(params[:id])
    @showdate = @valid_voucher.showdate
  end

  def new
    @show = Show.find params[:show_id]
    return redirect_to(edit_show_path(@show), :alert => t('season_setup.errors.no_performances_exist')) unless @show.showdates.count > 0
    @vouchertypes = Vouchertype.nonbundle_vouchertypes(@show.season)
    return redirect_to(edit_show_path(@show), :alert => t('season_setup.errors.no_redemptions_without_vouchertypes', :season => Option.humanize_season(@show.season))) unless @vouchertypes.count > 0
    @valid_voucher = ValidVoucher.new(:start_sales => @show.listing_date)
    # special case: if showdate has ANY stream-on-demand perfs, default the end-sales time to the
    # first such perf's showtime.  (if the user displays 'stream' or 'in-theater' on
    # the form, the date menus disappear anyway in favor of a "Minutes before curtain" field,
    # so doing this only affects anything if the show has a stream-anytime perf.)
    @minutes_before = Option.advance_sales_cutoff
    if (sd = @show.showdates.find_by(:stream_anytime => true))
      @valid_voucher.end_sales = sd.thedate - @minutes_before.minutes
    end
  end

  def edit
    @valid_voucher = ValidVoucher.find(params[:id])
    @show = @valid_voucher.showdate.show
  end

  def update
    @valid_voucher = ValidVoucher.find(params[:id])
    args = params[:valid_voucher]
    # max_sales_for_type if blank should be "infinity"
    if args[:max_sales_for_type].blank?
      args[:max_sales_for_type] = ValidVoucher::INFINITE
    end
    if @valid_voucher.update_attributes(args)
      redirect_to edit_show_path(@valid_voucher.showdate.show), :notice => 'Update successful.'
    else
      redirect_to edit_valid_voucher_path(@valid_voucher), :alert => @valid_voucher.errors.as_html
    end
  end

  def create
    args = params[:valid_voucher]
    preserve = params[:preserve] || {}
    vt = params[:vouchertypes]
    sd = params[:showdates]
    back = new_valid_voucher_path(:show_id => params[:show_id])
    return redirect_to(back, :alert => t('season_setup.must_select_showdates')) if sd.blank?
    return redirect_to(back, :alert => t('season_setup.must_select_vouchertypes')) if vt.blank?
    vouchertypes = Vouchertype.find vt
    showdates = Showdate.find sd
    # max_sales_for_type if blank should be "infinity"
    args[:max_sales_for_type] = ValidVoucher::INFINITE if args[:max_sales_for_type].blank?

    # params[:before_or_after] is either '+1' or '-1' to possibly negate minutes_before_curtain
    # (so the value stored is "Minutes before", but may be negative to indicate "minutes after")
    args[:before_showtime] = (params[:minutes_before].to_i * params[:before_or_after].to_i).minutes

    updater = RedemptionBatchUpdater.new(showdates,vouchertypes,
      :valid_voucher_params => args, :preserve => preserve)
    if updater.update
      redirect_to edit_show_path(params[:show_id]), :notice => "Successfully updated #{vouchertypes.size} voucher type(s) on #{showdates.size} showdate(s)."
    else
      redirect_to(back,:alert => t('season_setup.no_valid_vouchers_added', :error_message => updater.error_message))
    end
  end

  def destroy
    id = params[:id].to_i
    begin
      ValidVoucher.find(id).destroy
      # Success: hide the partial associated with this valid-voucher
      render :js => %Q{\$('#valid_voucher_#{id}').hide();}
    rescue ActiveRecord::RecordNotFound
      render :js => %Q{alert("Deletion failed: valid voucher not found");}
    rescue RuntimeError => e
      render :js => %Q{alert("Deletion failed: #{e.message}");}
    end
  end

end
