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

  # GET /account_codes/1/edit
  def edit
    @account_code = AccountCode.find(params[:id])
  end

  # POST /account_codes
  # POST /account_codes.xml
  def create
    @account_code = AccountCode.new(params[:account_code])
    if @account_code.save
      flash[:notice] = 'AccountCode was successfully created.'
      redirect_to account_codes_path
    end
  end

  # PUT /account_codes/1
  # PUT /account_codes/1.xml
  def update
    @account_code = AccountCode.find(params[:id])
    if @account_code.update_attributes(params[:account_code])
      flash[:notice] = 'AccountCode was successfully updated.'
      redirect_to account_codes_path
    end
  end

  # DELETE /account_codes/1
  # DELETE /account_codes/1.xml
  def destroy
    @account_code = AccountCode.find(params[:id])
    @account_code.destroy or flash[:alert] = @account_code.errors_on(:base) 
    redirect_to account_codes_path
  end
end
