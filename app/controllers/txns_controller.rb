class TxnsController < ApplicationController

  before_filter :is_staff_filter

  def index
    # cache the Transaction Types table for faster rendering
    @page = (params[:page] || 1).to_i
    @txn_filter = params[:txn_filter]
    if (@customer = Customer.find_by_id(@txn_filter))
      @txns = Txn.paginate(:page => @page, :order => "txn_date DESC", :conditions => ["customer_id = ?", @customer.id])
      @header = "Transactions for #{@customer.full_name}"
    else
      @txns = Txn.paginate(:page => @page, :order => "txn_date DESC")
      @header = "Transactions"
    end
    @header = "No #{@header}" if @txns.empty?
  end

end
