class VouchertypesController < ApplicationController

  before_filter :is_boxoffice_manager_filter
  before_filter :has_at_least_one, :except => [:new, :create]

  private
  def at_least_one_vouchertype
    unless Vouchertype.find(:first)
      flash[:warning] = "You have not defined any voucher types yet."
      redirect_to :action => 'new'
    end
  end

  public
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @superadmin = is_admin
    # possibly limit pagination to only bundles or only subs
    earliest = Vouchertype.find(:first, :order => 'valid_date')
    latest = Vouchertype.find(:first, :order => 'expiration_date DESC')
    @years = (earliest.expiration_date.year .. latest.expiration_date.year)
    @filter = params[:filter].to_s
    case @filter
    when "Bundles"
      @vouchertypes = Vouchertype.bundle_vouchertypes
    when "Subscriptions"
      @vouchertypes = Vouchertype.subscription_vouchertypes
    when "Single Tickets (Comp)"
      @vouchertypes = Vouchertype.comp_vouchertypes
    when "Single Tickets (Revenue)"
      @vouchertypes = Vouchertype.revenue_vouchertypes
    else # ALL
      @vouchertypes = Vouchertype.find(:all)
    end
    @season = params[:season] || "All"
    if (@season != "All")
      @vouchertypes.reject! { |vt| !(vt.expiration_date.between?(Time.now.at_beginning_of_season(@season), Time.now.at_end_of_season(@season))) }
    end
    @vouchertypes = @vouchertypes.sort_by(&:expiration_date).reverse
    if @vouchertypes.empty?
      flash[:warning] = "No vouchertypes matched your criteria."
    end
  end

  def new
    @vouchertype = Vouchertype.new
  end

  def create
    unless params[:vouchertype][:included_vouchers].is_a?(Hash)
      params[:vouchertype][:included_vouchers] = Hash.new
    end
    @vouchertype = Vouchertype.new(params[:vouchertype])
    if @vouchertype.save
      Txn.add_audit_record(:txn_type => 'config', :logged_in_id => logged_in_id,
                           :commments => "Create voucher type #{@vouchertype.name}")
      if @vouchertype.bundle?
        flash[:notice] = 'Please specify bundle quantities now.'
        redirect_to :action => 'edit', :id => @vouchertype
      else
        flash[:notice] = 'Vouchertype was successfully created.'
        redirect_to :action => 'list'
      end
    else
      render :action => 'new'
    end
  end

  def edit
    @vouchertype = Vouchertype.find(params[:id])
    @num_vouchers = @vouchertype.vouchers.count
    if @num_vouchers > 0
      flash[:warning] = "#{@num_vouchers} vouchers of this voucher type have already been issued.  Any changes  you make will be retroactively reflected to all of them.  If this is not what you want, click Cancel below."
    end
  end

  def update
    @vouchertype = Vouchertype.find(params[:id])
    @num_vouchers = @vouchertype.vouchers.count
    was_bundle_before = @vouchertype.bundle?
    unless @vouchertype.included_vouchers.is_a?(Hash)
      @vouchertype.included_vouchers = Hash.new
    end
    if @vouchertype.update_attributes(params[:vouchertype])
      Txn.add_audit_record(:txn_type => 'config', :logged_in_id => logged_in_id,
                           :comments => "Modify voucher type #{@vouchertype.name}")
      if @vouchertype.bundle? and !was_bundle_before
        flash[:notice] = 'Please edit bundle quantities now.'
        redirect_to :action => 'edit', :id => @vouchertype
      else
        flash[:notice] = 'Vouchertype was successfully updated.'
        redirect_to :action => 'list'
      end
    else
      flash[:notice] = 'Update failed, please re-check information and try again'
      render :action => 'edit'
    end
  end

  def destroy
    unless is_admin
      flash[:notice] = "Only superadmin can destroy vouchertypes."
      redirect_to :action => 'list'
      return
    end
    v = Vouchertype.find(params[:id])
    if ((c = v.vouchers.count) > 0)
      flash[:notice] = "Can't destroy this voucher type, because there are
                        #{c} issued vouchers of this type."
      redirect_to :action => 'list'
      return
    end
    name = v.name
    v.destroy
    Txn.add_audit_record(:txn_type => 'config', :logged_in_id => logged_in_id,
                         :comments => "Destroy voucher type #{name}")
    redirect_to :action => 'list'
  end
end
