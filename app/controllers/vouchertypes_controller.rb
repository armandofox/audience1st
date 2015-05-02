class VouchertypesController < ApplicationController

  before_filter :is_boxoffice_manager_filter
  before_filter :has_at_least_one, :except => [:new, :create]

  private
  def at_least_one_vouchertype
    unless Vouchertype.find(:first)
      flash[:alert] = "You have not defined any voucher types yet."
      redirect_to new_vouchertype_path
    end
  end

  public
  
  def index
    @superadmin = is_admin
    # possibly limit pagination to only bundles or only subs
    @earliest = Vouchertype.find(:first, :order => 'season').season
    @latest = Vouchertype.find(:first, :order => 'season DESC').season
    @filter = params[:filter].to_s
    @season = params[:season] || Time.this_season
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
    @vouchertype = Vouchertype.find(params[:id])
    @vouchertype.name[0,0] = 'Copy of '
    render :action => :new
  end

  def create
    unless params[:vouchertype][:included_vouchers].is_a?(Hash)
      params[:vouchertype][:included_vouchers] = Hash.new
    end
    @vouchertype = Vouchertype.new(params[:vouchertype])
    if @vouchertype.save
      Txn.add_audit_record(:txn_type => 'config', :logged_in_id => logged_in_id,
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
    @vouchertype = Vouchertype.find(params[:id])
    @num_vouchers = @vouchertype.vouchers.count
    @valid_voucher = @vouchertype.valid_vouchers.first if @vouchertype.bundle?
    if @num_vouchers > 0
      flash[:alert] = "#{@num_vouchers} vouchers of this voucher type have already been issued.  Any changes  you make will be retroactively reflected to all of them.  If this is not what you want, click Cancel below."
    end
  end

  def update
    @vouchertype = Vouchertype.find(params[:id])
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
      Txn.add_audit_record(:txn_type => 'config', :logged_in_id => logged_in_id,
                           :comments => "Modify voucher type #{@vouchertype.name}")
      flash[:notice] = 'Vouchertype was successfully updated.'
      redirect_to vouchertypes_path, :season => @vouchertype.season
    else
      flash[:alert] = 'Update failed, please re-check information and try again: ' + errors_as_html(@vouchertype)
      redirect_to edit_vouchertype_path(@vouchertype)
    end
  end

  def destroy
    v = Vouchertype.find(params[:id])
    errors = []
    errors << "there are #{c} issued vouchers of this type" if (c=v.vouchers.count) > 0
    errors << " it's listed as valid for purchase for the following shows: #{shows}" if
      !(shows = v.valid_vouchers.map { |v| v.showdate.show.name }.uniq.join(', ')).blank?
    if !errors.empty?
      flash[:notice] = "Can't destroy this voucher types, because " << errors.join(" and ")
    else
      name = v.name
      season = v.season
      v.destroy
      Txn.add_audit_record(:txn_type => 'config', :logged_in_id => logged_in_id,
        :comments => "Destroy voucher type #{name}")
    end
    redirect_to vouchertypes_path, :season => season
  end
end
