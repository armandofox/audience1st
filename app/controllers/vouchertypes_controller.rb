class VouchertypesController < ApplicationController

  before_action :is_boxoffice_manager_filter
  before_action :has_at_least_one, :except => [:new, :create]
  before_action :load_vouchertype, :only => [:clone, :edit, :update, :destroy]

  after_action :remember_vouchertype_season!, :except => :index

  private

  def load_vouchertype
    @vouchertype = Vouchertype.
      where(:id => params[:id]).
      includes(:vouchers,:valid_vouchers).
      first
  end

  def remember_vouchertype_season!(season = @vouchertype.season)
    session[:vouchertype_season] = season.to_i
  end
  def vouchertype_season
    (session[:vouchertype_season] || Time.this_season).to_i
  end

  public
  
  def index
    @season = (params[:season] || vouchertype_season).to_i
    remember_vouchertype_season! @season
    @superadmin = current_user().is_admin
    @vouchertypes = Vouchertype.
      where(:season => @season).
      includes(:account_code).
      order(:display_order,:category,:created_at)
    if @vouchertypes.empty?
      flash[:alert] = "No vouchertypes matched your criteria."
    end
  end

  def new
    @vouchertype = Vouchertype.new(:category => 'revenue', :season => vouchertype_season)
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
      flash[:notice] = ['Vouchertype could not be created: ', @vouchertype.errors.as_html]
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

    Vouchertype.transaction do
      begin
        if params[:valid_voucher]
          valid_voucher = @vouchertype.valid_vouchers.first
          valid_voucher.update_attributes!(params[:valid_voucher])
        end
        @vouchertype.update_attributes!(params[:vouchertype].except(:valid_voucher))
        Txn.add_audit_record(:txn_type => 'config', :logged_in_id => current_user.id,
          :comments => "Modify voucher type #{@vouchertype.name}")
        flash[:notice] = 'Vouchertype was successfully updated.'
        redirect_to vouchertypes_path, :season => @vouchertype.season
      rescue StandardError => e
        flash[:alert] = "Update failed: #{e.message}"
        redirect_to edit_vouchertype_path(@vouchertype)
      end
    end
  end

  def destroy
    c = @vouchertype.vouchers.count
    return redirect_to(vouchertypes_path(:season => @vouchertype.season), :alert => "Can't delete this voucher type because #{c} of them have already been issued") if c > 0

    @vouchertype.destroy
    Txn.add_audit_record(:txn_type => 'config', :logged_in_id => current_user.id,
      :comments => "Destroy voucher type #{@vouchertype.name}")
    redirect_to(vouchertypes_path(:season => @vouchertype.season), :notice => "Voucher type '#{@vouchertype.name}' deleted.")

  end
end
