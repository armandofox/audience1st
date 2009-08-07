class DonationFundsController < ApplicationController

  before_filter :is_staff_filter

  # GET /donation_funds
  # GET /donation_funds.xml
  def index
    @donation_funds = DonationFund.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @donation_funds }
    end
  end

  # GET /donation_funds/1
  # GET /donation_funds/1.xml
  def show
    @donation_fund = DonationFund.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @donation_fund }
    end
  end

  # GET /donation_funds/new
  # GET /donation_funds/new.xml
  def new
    @donation_fund = DonationFund.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @donation_fund }
    end
  end

  # GET /donation_funds/1/edit
  def edit
    @donation_fund = DonationFund.find(params[:id])
  end

  # POST /donation_funds
  # POST /donation_funds.xml
  def create
    @donation_fund = DonationFund.new(params[:donation_fund])

    respond_to do |format|
      if @donation_fund.save
        flash[:notice] = 'DonationFund was successfully created.'
        format.html { redirect_to(@donation_fund) }
        format.xml  { render :xml => @donation_fund, :status => :created, :location => @donation_fund }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @donation_fund.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /donation_funds/1
  # PUT /donation_funds/1.xml
  def update
    @donation_fund = DonationFund.find(params[:id])

    respond_to do |format|
      if @donation_fund.update_attributes(params[:donation_fund])
        flash[:notice] = 'DonationFund was successfully updated.'
        format.html { redirect_to(@donation_fund) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @donation_fund.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /donation_funds/1
  # DELETE /donation_funds/1.xml
  def destroy
    @donation_fund = DonationFund.find(params[:id])
    @donation_fund.destroy

    respond_to do |format|
      format.html { redirect_to(donation_funds_url) }
      format.xml  { head :ok }
    end
  end
end
