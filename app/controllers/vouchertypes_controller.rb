class VouchertypesController < ApplicationController

  before_filter :is_boxoffice_manager_filter
  before_filter :has_at_least_one, :except => [:new, :create]
  before_filter :load_vouchertype, :only => [:clone, :edit, :update, :destroy]

  private

  def load_vouchertype
    @vouchertype = Vouchertype.find params[:id]
  end

  public
  
  def index
    return redirect_to(params.merge(:season => Time.this_season, :only_path => true)) unless (@season = params[:season].to_i) > 0
    @superadmin = current_user().is_admin
    # possibly limit pagination to only bundles or only subs
    @earliest = Vouchertype.find(:first, :order => 'season').season
    @latest = Vouchertype.find(:first, :order => 'season DESC').season
    @filter = params[:filter].to_s
    limit_to_season = (@season.to_i > 0) ? @season.to_i : nil
    case @filter
    when "Bundles"
      @vouchertypes = Vouchertype.bundle_vouchertypes(limit_to_season)
    when "Subscriptions"
      @vouchertypes = Vouchertype.subscription_vouchertypes(limit_to_season)
    when "Single Tickets (Comp)"
      @vouchertypes = Vouchertype.comp_vouchertypes(limit_to_season)
    when "Single Tickets (Revenue)"
      @vouchertypes = Vouchertype.revenue_vouchertypes(limit_to_season)
    when "Nonticket Products"
      @vouchertypes = Vouchertype.nonticket_vouchertypes(limit_to_season)
    else # ALL
      @vouchertypes = Vouchertype.find(:all)
      if (limit_to_season)
        @vouchertypes.reject! { |vt| vt.season && (vt.season != limit_to_season) }
      end
    end
    @vouchertypes = @vouchertypes.sort_by do |v|
      (v.bundle? ? 0 : 1e6) + v.season*1000 + v.display_order
    end
    if @vouchertypes.empty?
      flash[:alert] = "No vouchertypes matched your criteria."
    end
  end

  def new
    @vouchertype = Vouchertype.new(:category => :revenue)
  end

  def clone
    @vouchertype.name[0,0] = 'Copy of '
    render :action => :new
  end

  def create
    unless params[:vouchertype][:included_vouchers].is_a?(Hash)
      params[:vouchertype][:included_vouchers] = Hash.new
    end
    @vouchertype = Vouchertype.new(params[:vouchertype])
    if @vouchertype.save
      Txn.add_audit_record(:txn_type => 'config', :logged_in_id => current_user.id,
                           :commments => "Create voucher type #{@vouchertype.name}")
      if @vouchertype.bundle? && @vouchertype.included_vouchers.empty?
        flash[:notice] = 'Please specify bundle quantities now.'
        redirect_to edit_vouchertype_path(@vouchertype)
      else
        flash[:notice] = 'Vouchertype was successfully created.'
        if params[:commit] =~ /another/i
          redirect_to new_vouchertype_path
        else
          redirect_to vouchertypes_path, :season => @vouchertype.season
        end
      end
    else
      render :action => 'new'
    end
  end

  def edit
    @num_vouchers = @vouchertype.vouchers.count
    @valid_voucher = @vouchertype.valid_vouchers.first if @vouchertype.bundle?
    if @num_vouchers > 0
      flash[:alert] = "#{@num_vouchers} vouchers of this voucher type have already been issued.  Any changes  you make will be retroactively reflected to all of them.  If this is not what you want, click Cancel below."
    end
  end

  def update
    @num_vouchers = @vouchertype.vouchers.count
    unless @vouchertype.included_vouchers.is_a?(Hash)
      @vouchertype.included_vouchers = Hash.new
    end
    # this is a hack, since we should really use the nested-attribute
    #  form tags to do this, but the view is messy right now.
    if params[:valid_voucher]
      params[:valid_voucher][:id] = @vouchertype.valid_vouchers.first.id
      params[:vouchertype][:valid_vouchers_attributes] = [ params[:valid_voucher] ]
    end
    if @vouchertype.update_attributes(params[:vouchertype])
      Txn.add_audit_record(:txn_type => 'config', :logged_in_id => current_user.id,
                           :comments => "Modify voucher type #{@vouchertype.name}")
      flash[:notice] = 'Vouchertype was successfully updated.'
      redirect_to vouchertypes_path, :season => @vouchertype.season
    else
      flash[:alert] = ['Update failed, please re-check information and try again: ', @vouchertype]
      redirect_to edit_vouchertype_path(@vouchertype)
    end
  end

  def destroy
    c = @vouchertype.vouchers.count
    return redirect_with(vouchertypes_path(:season => @vouchertype.season), :alert => "Can't delete this voucher type because #{c} of them have already been issued") if c > 0

    @vouchertype.destroy
    Txn.add_audit_record(:txn_type => 'config', :logged_in_id => current_user.id,
      :comments => "Destroy voucher type #{@vouchertype.name}")
    redirect_with(vouchertypes_path(:season => @vouchertype.season), :notice => "Voucher type '#{@vouchertype.name}' deleted.")

  end
end
