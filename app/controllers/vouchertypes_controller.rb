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
    @vouchertype_pages, @vouchertypes = paginate :vouchertypes, :per_page => 25
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
      return
    end
    v = Vouchertype.find(params[:id])
    name = v.name
    v.destroy
    Txn.add_audit_record(:txn_type => 'config', :logged_in_id => logged_in_id,
                         :comments => "Destroy voucher type #{name}")
    redirect_to :action => 'list'
  end
end
