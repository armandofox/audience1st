class VouchertypesController < ApplicationController

  before_filter :is_boxoffice_manager_filter

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
    latest = Vouchertype.find(:first, :order => 'valid_date DESC')
    @years = (earliest.valid_date.year .. latest.valid_date.year)
    @filter = params[:filter].to_s
    case @filter
    when "Bundles"
      c = "is_bundle = 1"
    when "Subscriptions"
      c = "is_subscription = 1"
    else
      c = 'TRUE'
    end
    @season = params[:season] || "All"
    conditions = 
      if (@season == "All")
        [c]
      else
        s = Time.now.at_beginning_of_season(@season)
        e = Time.now.at_end_of_season(@season)
        ["#{c} AND (expiration_date BETWEEN ? AND ?)", s, e]
      end
    @vouchertypes = Vouchertype.find(:all, :conditions => conditions,
                                     :order => "valid_date, is_subscription")
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
      if @vouchertype.is_bundle?
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
  end

  def update
    @vouchertype = Vouchertype.find(params[:id])
    was_bundle_before = @vouchertype.is_bundle?
    unless @vouchertype.included_vouchers.is_a?(Hash)
      @vouchertype.included_vouchers = Hash.new
    end
    if @vouchertype.update_attributes(params[:vouchertype])
      Txn.add_audit_record(:txn_type => 'config', :logged_in_id => logged_in_id,
                           :comments => "Modify voucher type #{@vouchertype.name}")
      if @vouchertype.is_bundle? and !was_bundle_before
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
