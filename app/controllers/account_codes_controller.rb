class AccountCodesController < ApplicationController

  before_filter :is_staff_filter

  # GET /account_codes
  # GET /account_codes.xml
  def index
    list
  end
  def list
    @account_codes = AccountCode.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @account_codes }
    end
  end

  # GET /account_codes/new
  # GET /account_codes/new.xml
  def new
    @account_code = AccountCode.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @account_code }
    end
  end

  # GET /account_codes/1/edit
  def edit
    @account_code = AccountCode.find(params[:id])
  end

  # POST /account_codes
  # POST /account_codes.xml
  def create
    @account_code = AccountCode.new(params[:account_code])

    respond_to do |format|
      if @account_code.save
        flash[:notice] = 'AccountCode was successfully created.'
        format.html { redirect_to :action => 'index' }
        format.xml  { render :xml => @account_code, :status => :created, :location => @account_code }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @account_code.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /account_codes/1
  # PUT /account_codes/1.xml
  def update
    @account_code = AccountCode.find(params[:id])

    respond_to do |format|
      if @account_code.update_attributes(params[:account_code])
        flash[:notice] = 'AccountCode was successfully updated.'
        format.html { redirect_to :action => 'index' }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @account_code.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /account_codes/1
  # DELETE /account_codes/1.xml
  def destroy
    @account_code = AccountCode.find(params[:id])
    @account_code.destroy

    respond_to do |format|
      format.html { redirect_to(account_codes_url) }
      format.xml  { head :ok }
    end
  end
end
