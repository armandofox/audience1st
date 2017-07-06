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
    msgs = ''
    vouchertypes = params[:valid_voucher].delete(:vouchertypes)
    return redirect_to(:back, :alert => 'You must select 1 or more show dates.') unless (vouchertypes && !vouchertypes.empty?)
    args = params[:valid_voucher]
    hours_before = (params[:end_is_relative].to_i > 0 ?
                    params[:hours_before].to_f.hours :
                    false)
    showdate = Showdate.find(args[:showdate_id])
    raise "New voucher type must be added to valid showdate" unless showdate.kind_of?(Showdate)
    addtojustone = params[:addtojustone].to_i
    if addtojustone.zero?
      # add voucher type to all dates
      showdate.show.showdates.each do |dt|
        args[:showdate_id] = dt.id
        vouchertypes.each do |vt_id| 
          args[:vouchertype_id] = vt_id
          vv = ValidVoucher.new(args)
          if hours_before
            vv.end_sales = dt.thedate - hours_before
          end
          unless vv.save
            msgs << %{Voucher type #{Vouchertype.find(vt_id).name} NOT added to
                #{dt.thedate.to_formatted_s(:date_only)}:
                #{vv.errors.full_messages.join(', ')}} << "<br/>"
          end
        end
      end
      if (msgs == '')
        msgs = 'Ticket type(s) added to all dates'
      end
    else
      # add to just one date
      vouchertypes.each do |vt_id|
        args[:vouchertype_id] = vt_id
        @validvoucher = ValidVoucher.new(args)
        if hours_before
          @validvoucher.end_sales = showdate.thedate - hours_before
        end
        if @validvoucher.save
          msgs << 'Added to performance on ' << showdate.printable_date 
        else
          msgs << @validvoucher.errors.full_messages.join(', ')
        end
      end
    end
    flash[:notice] = msgs
    if params[:commit] =~ /another/i
      redirect_to :action => :new, :showdate_id => showdate, :add_to_all => addtojustone.zero?
    else
      redirect_to edit_show_path(showdate.show)
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
      flash[:alert] = [e.message, @valid_voucher]
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
