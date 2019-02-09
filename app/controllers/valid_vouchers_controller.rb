class ValidVouchersController < ApplicationController

  before_filter :is_boxoffice_filter
  before_filter(:is_boxoffice_manager_filter,:except => :show)

  def show
    @valid_voucher = ValidVoucher.find(params[:id])
    @showdate = @valid_voucher.showdate
  end

  def new
    @show = Show.find params[:show_id]
    @vouchertypes = Vouchertype.nonbundle_vouchertypes(@show.season)
    @valid_voucher = ValidVoucher.new(:start_sales => @show.listing_date)
    @minutes_before = Option.advance_sales_cutoff
  end

  def edit
    @valid_voucher = ValidVoucher.find(params[:id])
    @show = @valid_voucher.showdate.show
  end

  def create
    args = params[:valid_voucher]
    show_id = params[:show_id]
    vouchertypes = Vouchertype.find(params[:vouchertypes])
    return redirect_to(:back, :alert => 'You must select 1 or more voucher types to add.') if vouchertypes.empty?
    args[:before_showtime] = params[:minutes_before].to_i.minutes if params[:end_is_relative].to_i > 0
    showdates = Showdate.find(params[:showdates])
    begin
      ValidVoucher.add_vouchertypes_to_showdates! showdates,vouchertypes,args
      redirect_to edit_show_path(show_id), :notice => "Successfully updated #{vouchertypes.size} voucher type(s) on #{showdates.size} showdate(s)."
    rescue ValidVoucher::CannotAddVouchertypeToMultipleShowdates => e
      redirect_to(new_valid_voucher_path,
        :alert => "NO changes were made, because some voucher type(s) could not be added to some show date(s)--try adding them one at a time to isolate specific errors.  #{e.message}")
    end
  end

  def update
    @valid_voucher = ValidVoucher.find(params[:id])
    flash_message = {}
    begin
      # this is ugly: we incur 2 database writes on an update if
      # end_is_relative  is set.
      @valid_voucher.update_attributes!(params[:valid_voucher])
      if params[:end_is_relative].to_i > 0
        @valid_voucher.update_attribute(:end_sales,
           @valid_voucher.showdate.thedate - params[:hours_before].to_f.hours)
      end
      flash_message = {:notice => 'Update successful'}
    rescue ValidVoucher::CannotAddVouchertypeToMultipleShowdates => e
      flash_message = {:alert => e.message}
    end
    redirect_to edit_show_path(@valid_voucher.showdate.show), flash_message
  end

  def destroy
    id = params[:id]
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
