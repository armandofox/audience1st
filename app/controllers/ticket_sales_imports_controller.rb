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

  def create
    @import = TicketSalesImport.new(
      :vendor => params[:vendor], :raw_data => params[:file].read,:processed_by => current_user)
    if @import.valid?
      @import.save!
      redirect_to edit_ticket_sales_import_path(@import)
    else
      redirect_to ticket_sales_imports_path, :alert => @import.errors.as_html
    end
  end

  def edit
    @import = TicketSalesImport.find params[:id]
    byebug
  end

end
