class TxnsController < ApplicationController

  before_filter :is_staff_filter

  def index
    # cache the Transaction Types table for faster rendering
    @page = (params[:page] || 1).to_i
    @txn_filter = params[:txn_filter]
    if (@customer = Customer.find_by_id(@txn_filter))
      @txns = Txn.
        where("customer_id = ?", @customer.id).
        includes(:customer, :show, :showdate, :voucher, :order).
        order("txn_date DESC").
        paginate(:page => @page)
      @header = "Transactions for #{@customer.full_name}"
    else
      @txns = Txn.all.order("txn_date DESC").paginate(:page => @page)
      @header = "Transactions"
    end
    @header = "No #{@header}" if @txns.empty?
  end

end
