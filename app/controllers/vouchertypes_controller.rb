class VouchertypesController < ApplicationController

  before_action :is_boxoffice_manager_filter
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
  end

  def new
    @vouchertype = Vouchertype.new(:category => 'revenue', :season => vouchertype_season)
  end

  def clone
    @vouchertype = @vouchertype.dup
    @vouchertype.name[0,0] = 'Copy of '
    render :action => :new
  end

  def create
    creation_params =
      params.require(:vouchertype).
        permit(:category, :name, :price, :offer_public, :season, :display_order, :fulfillment_needed, :walkup_sale_allowed, :changeable, :subscription, :comments, :account_code_id)
    @vouchertype = Vouchertype.new(creation_params)
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
      redirect_to new_vouchertype_path, :alert => ('Vouchertype could not be created: ' << @vouchertype.errors.as_html)
    end
  end

  def edit
    @num_vouchers = @vouchertype.vouchers.count
    @valid_voucher = @vouchertype.valid_vouchers.first if @vouchertype.bundle?
    if @num_vouchers > 0
      flash.now[:alert] ||= ''
      flash.now[:alert] += I18n.translate('season_setup.vouchers_already_issued', :num => @num_vouchers)
    end
  end

  def update
    # :rails5: this can be simplified since Rails 5.1+ allows :included_vouchers => {} to
    #  pass through ANY keys in that hash
    included_voucher_keys = params[:vouchertype][:included_vouchers] ? params[:vouchertype][:included_vouchers].keys : []
    vouchertype_update_params =
      params.require(:vouchertype).
        permit(:name, :price, :offer_public, :season,
                :display_order, :fulfillment_needed, :walkup_sale_allowed, :changeable,
                :subscription, :comments, :account_code_id, :account_code,
                :included_vouchers => included_voucher_keys)
    valid_voucher_update_params = params.permit(:valid_voucher => [:max_sales_for_type, :start_sales, :end_sales, :promo_code])
    @num_vouchers = @vouchertype.vouchers.count
    unless @vouchertype.included_vouchers.is_a?(Hash)
      @vouchertype.included_vouchers = Hash.new
    end

    Vouchertype.transaction do
      begin
        if valid_voucher_update_params
          valid_voucher = @vouchertype.valid_vouchers.first
          valid_voucher.update_attributes!(valid_voucher_update_params[:valid_voucher])
        end
        @vouchertype.update_attributes!(vouchertype_update_params)
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
