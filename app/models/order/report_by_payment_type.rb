class Order < ActiveRecord::Base
  class ReportByPaymentType

    attr_reader :from, :to, :credit_card, :cash, :check

    def initialize(from,to)
      @from,@to = from,to
    end

    def run
      orders = 
        Order.
        includes(:items, :customer, :purchaser, :processed_by,
        :donations => :account_code,
        :vouchers  => [:showdate,:vouchertype]).
        where(:sold_on => @from..@to).
        order(:sold_on => :asc)
      
      @credit_card = orders.where(:purchasemethod => Purchasemethod.get_type_by_name(:web_cc))
      @cash = orders.where(:purchasemethod => Purchasemethod.get_type_by_name(:box_cash))
      @check = orders.where(:purchasemethod => Purchasemethod.get_type_by_name(:box_chk))
      self
    end
  end
end
