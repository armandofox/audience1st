class TxnController < ApplicationController

  before_filter :is_staff_filter

  def index
    redirect_to :action => 'list'
  end

  def list
    # cache the Transaction Types table for faster rendering
    if (@txn_filter = params[:txns_filter])
      @txn_pages, @txns = paginate :txns, :per_page => 100, :order_by => "txn_date DESC", :conditions => ["customer_id = ?", @txn_filter]
    else
      @txn_pages, @txns = paginate :txns, :per_page => 100, :order_by => "txn_date DESC"
    end
  end

end
