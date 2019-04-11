class TicketSalesImportsController < ApplicationController

  def index
    @ticket_sales_imports = TicketSalesImport.all.sorted
  end

end
