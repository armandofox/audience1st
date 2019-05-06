class TicketSalesImportsController < ApplicationController

  before_filter :is_boxoffice_manager_filter

  # View all imports, also provides a form to create a new import by uploading a file.
  # The view provides a dropdown populated from TicketSalesImporter::IMPORTERS, which
  # should be used to set the 'vendor' field of the import.
  def index
    @ticket_sales_imports = TicketSalesImport.all.sorted
    @vendors = TicketSalesImport::IMPORTERS
    @import = TicketSalesImport.new(:vendor => @vendors.first)
  end

  # create: storegrab the uploaded data, create a new TicketSalesImport instance whose 'vendor'
  # field is populated from the dropdown on the index page and whose 'raw_data' is populated
  # from the contents of the uploaded file

  def new
    @import = TicketSalesImport.new(
      :vendor => params[:vendor], :raw_data => params[:file].read,:processed_by => current_user)
    return redirect_to(ticket_sales_imports_path, :alert => @import.errors.as_html) unless @import.valid?
    @import.parse
  end

end
