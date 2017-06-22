class AccountCodesController < ApplicationController

  before_filter :is_staff_filter

  # GET /account_codes
  # GET /account_codes.xml
  def index
    @account_codes = AccountCode.all
  end

  def new
    @account_code = AccountCode.new
  end

  def edit
    @account_code = AccountCode.find(params[:id])
  end

  def create
    @account_code = AccountCode.new(params[:account_code])
    if @account_code.save
      flash[:notice] = 'Account code was successfully created.'
    else
      flash[:alert] = ['Account code could not be created:', @account_code]
    end
    redirect_to account_codes_path
  end

  def update
    @account_code = AccountCode.find(params[:id])
    if @account_code.update_attributes(params[:account_code])
      flash[:notice] = 'AccountCode was successfully updated.'
    else
      flash[:alert] = ['AccountCode could not be updated:', @account_code]
    end
    redirect_to account_codes_path
  end

  def destroy
    @account_code = AccountCode.find(params[:id])
    @account_code.destroy or flash[:alert] = @account_code.errors[:base] 
    redirect_to account_codes_path
  end
end
