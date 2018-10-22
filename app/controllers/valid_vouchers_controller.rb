class ValidVouchersController < ApplicationController

  before_filter :is_boxoffice_filter
  before_filter(:is_boxoffice_manager_filter,:except => :show)

  def show
    @valid_voucher = ValidVoucher.find(params[:id])
    @showdate = @valid_voucher.showdate
  end

  def new
    @showdate_id = params[:showdate_id]
    unless (@showdate = Showdate.find_by_id(@showdate_id))
      return redirect_to(shows_path, :alert => "New voucher must be associated with a showdate")
    end
    @add_to_all = params[:add_to_all]
    @vouchertypes = Vouchertype.nonbundle_vouchertypes(@showdate.season)
    @valid_voucher = ValidVoucher.new
    # set some convenient defaults for new valid_voucher
    @valid_voucher.start_sales = @showdate.show.listing_date
    @valid_voucher.end_sales = @showdate.end_advance_sales
  end

  def create
    args = params[:valid_voucher]
    return redirect_to(:back, :alert => 'You must select 1 or more show dates.') unless
      (vouchertypes = Vouchertype.find(args.delete(:vouchertypes))) &&
      !vouchertypes.empty?
    args[:before_showtime] = params[:hours_before].to_f.hours if params[:end_is_relative].to_i > 0
    @add_to_all = (params[:add_to_all].to_i > 0)
    @showdate = Showdate.find(args[:showdate_id])
    showdates = if @add_to_all then @showdate.show.showdates else [@showdate] end
    begin
      ValidVoucher.add_vouchertypes_to_showdates! showdates,vouchertypes,args
      redirect_to edit_show_path(@showdate.show), :notice => "Successfully added #{vouchertypes.size} voucher types to #{showdates.size} showdate(s)."
    rescue ValidVoucher::CannotAddVouchertypeToMultipleShowdates => e
      redirect_to(new_valid_voucher_path(:showdate_id => @showdate.id,:add_to_all => @add_to_all),
        :alert => "NO changes were made, because some voucher type(s) could not be added to some show date(s)--try adding them one at a time to isolate specific errors.  #{e.message}")
    end
  end

  def edit
    @valid_voucher = ValidVoucher.find(params[:id])
    @showdate = @valid_voucher.showdate
  end

  def update
    @valid_voucher = ValidVoucher.find(params[:id])
    begin
      # this is ugly: we incur 2 database writes on an update if
      # end_is_relative  is set.
      @valid_voucher.update_attributes!(params[:valid_voucher])
      if params[:end_is_relative].to_i > 0
        @valid_voucher.update_attribute(:end_sales,
           @valid_voucher.showdate.thedate - params[:hours_before].to_f.hours)
      end
      flash[:notice] = 'Update successful'
    rescue Exception => e
      flash[:alert] = [e.message, @valid_voucher.errors.as_html]
    end
    redirect_to edit_show_path(@valid_voucher.showdate.show)
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
