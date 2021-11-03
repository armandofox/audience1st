class TicketSalesImportsController < ApplicationController

  before_filter :is_boxoffice_filter

  # View all imports, also provides a form to create a new import by uploading a file.
  # The view provides a dropdown populated from TicketSalesImporter::IMPORTERS, which
  # should be used to set the 'vendor' field of the import.
  def index
    @ticket_sales_imports = TicketSalesImport.completed.sorted
    @vendors = TicketSalesImport::IMPORTERS.sort
    @default_vendor = params[:vendor]
    # if we were sent here as the result of an auto-expiring timer during import,
    # display a warning to that effect.
    flash.now[:alert] = t('import.was_cancelled') if params[:warn]
  end

  # create: grabs uploaded data, create a new TicketSalesImport instance whose 'vendor'
  # field is populated from the dropdown on the index page and whose 'raw_data' is populated
  # from the contents of the uploaded file; then immediately continue to Edit action 


  def create
    return redirect_to(ticket_sales_imports_path, :alert => 'Please choose a will-call list to upload.') if params[:file].blank?
    @import = TicketSalesImport.new(ticketsalesimport_params)
    @import.processed_by = current_user
    return redirect_to(ticket_sales_imports_path(:vendor => @import.vendor), :alert => @import.errors.as_html) unless @import.valid?
    @import.parser.parse or return redirect_to(ticket_sales_imports_path(:vendor => @import.vendor), :alert => @import.errors.as_html)
    @import.save or return redirect_to(ticket_sales_imports_path(:vendor => @import.vendor), :alert => @import.errors.as_html)
    redirect_to edit_ticket_sales_import_path(@import), :alert => (@import.warnings.as_html if !@import.warnings.empty?)
  end

  def show
    @import = TicketSalesImport.find params[:id]
  end
  
  def edit
    return unless check_not_imported_or_in_progress(params[:id])
    @import.check_sales_limits
    @imported_orders = @import.imported_orders.sort do |o1, o2|
      o1.from_import.last <=> o2.from_import.last
    end
    flash.now[:alert] = @import.warnings.as_html if !@import.warnings.empty?
  end

  # Finalize the import according to dropdown menu selections
  def update
    return unless check_not_imported_or_in_progress(params[:id])
    if @import.finalize(params[:customer_id] || {})
      redirect_to ticket_sales_imports_path, :notice => [
                    t('import.success.num_tickets', :count => @import.tickets_sold),
                    t('import.success.total_customers', :count => @import.existing_customers + @import.new_customers),
                    t('import.success.existing_customers', :count => @import.existing_customers),
                    t('import.success.new_customers_created', :count => @import.new_customers)].
                                                          join(' ')
    else
      redirect_to(edit_ticket_sales_import_path(@import),
                  :alert => t('import.import_failed', :message => @import.errors.as_html))
    end
  end

  def destroy
    begin
      i = TicketSalesImport.find params[:id]
      i.destroy
      request.xhr? ? render(:status => :ok, :nothing => true) : redirect_to(ticket_sales_imports_path, :notice => t('import.import_cancelled', :filename => i.filename))
    rescue ActiveRecord::RecordNotFound
      request.xhr? ? render(:status => :ok, :nothing => true) : redirect_to(ticket_sales_imports_path, :notice => t('import.was_cancelled'))
    end
  end

  private

  def check_not_imported_or_in_progress(id)
    @import = TicketSalesImport.find_by :id => id
    valid = false
    if @import.nil?
      redirect_to ticket_sales_imports_path, :alert => t('import.was_cancelled')
    elsif @import.completed?
      redirect_to ticket_sales_imports_path, :alert => t('import.already_imported', :user => @import.processed_by.full_name)
    elsif !@import.valid?
      redirect_to ticket_sales_imports_path, :alert => @import.errors.as_html
    else
      valid = true
    end
    valid
  end

  def ticketsalesimport_params
    permitted = params.permit(:vendor, :file)
    {
      vendor: permitted[:vendor],
      raw_data: permitted[:file].read,
      filename: permitted[:file].original_filename,
      completed: false, processed_by: current_user,
      existing_customers: 0,
      new_customers: 0,
      tickets_sold: 0 
    }
  end
end
