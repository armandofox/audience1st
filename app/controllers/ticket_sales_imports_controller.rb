class TicketSalesImportsController < ApplicationController

  before_filter :is_boxoffice_filter

  # View all imports, also provides a form to create a new import by uploading a file.
  # The view provides a dropdown populated from TicketSalesImporter::IMPORTERS, which
  # should be used to set the 'vendor' field of the import.
  def index
    @ticket_sales_imports = TicketSalesImport.completed.sorted
    @in_progress_imports = TicketSalesImport.in_progress.sorted
    @vendors = TicketSalesImport::IMPORTERS
  end

  # upload: grab uploaded data, create a new TicketSalesImport instance whose 'vendor'
  # field is populated from the dropdown on the index page and whose 'raw_data' is populated
  # from the contents of the uploaded file

  def create
    return redirect_to(ticket_sales_imports_path, :alert => 'Please choose a will-call list to upload.') if params[:file].blank?
    @import = TicketSalesImport.new(ticketsalesimport_params)
    if @import.valid?
      @import.save!
      redirect_to edit_ticket_sales_import_path(@import)
    else
      redirect_to ticket_sales_imports_path, :alert => @import.errors.as_html
    end
  end

  def edit
    @import = TicketSalesImport.find params[:id]
    @import.parse
    @importable = ! (@import.completed? || @import.importable_orders.all?(&:already_imported?))
    if !@import.errors.empty?
      @import.destroy
      return redirect_to(ticket_sales_imports_path, :alert => @import.errors.as_html)
    end
    @import.check_sales_limits
    flash.now[:alert] = @import.warnings.as_html if !@import.warnings.empty?
  end

  # Finalize the import according to dropdown menu selections
  def update
    import = TicketSalesImport.find params[:id]
    order_hash = params[:o]
    # each hash key is the id of a saved (but not finalized) order
    # each hash value is {:action => a, :customer_id => c, :first => f, :last => l, :email => e}
    #  if action is ALREADY_IMPORTED, do nothing
    #  if action is MAY_CREATE_NEW_CUSTOMER, create new customer & finalize order
    #  if action is MUST_USE_EXISTING_CUSTOMER, attach given customer ID & finalize order
    begin
      Order.transaction do
        order_hash.each_pair do |order_id, o|
          order = Order.find order_id
          order.ticket_sales_import = import
          order.processed_by = current_user
          sold_on = Time.zone.parse o[:transaction_date]
          if o[:action] == ImportableOrder::MAY_CREATE_NEW_CUSTOMER && o[:customer_id].blank?
            customer = Customer.new(:first_name => o[:first], :last_name => o[:last],
              :email => o[:email], :ticket_sales_import => import)
            order.finalize_with_new_customer!(customer, current_user, sold_on)
            import.new_customers += 1
          else
            order.finalize_with_existing_customer_id!(o[:customer_id], current_user, sold_on)
            import.existing_customers += 1
          end
          import.tickets_sold += order.ticket_count unless o[:action] == ImportableOrder::ALREADY_IMPORTED
        end
        import.completed = true
        import.save!
        flash[:notice] = [
          t('import.success.num_tickets', :count => import.tickets_sold),
          t('import.success.total_customers', :count => import.existing_customers + import.new_customers),
          t('import.success.existing_customers', :count => import.existing_customers),
          t('import.success.new_customers_created', :count => import.new_customers)].
          join(' ')
      end
    rescue StandardError => e
      flash[:alert] = t('import.import_failed', :message => e.message)
    end
    redirect_to ticket_sales_imports_path
  end

  def destroy
    i = TicketSalesImport.find(params[:id])
    flash[:notice] = I18n.translate('import.import_cancelled', :filename => i.filename)
    i.destroy
    redirect_to ticket_sales_imports_path
  end

  private

  def ticketsalesimport_params
    permitted = params.permit(:vendor, :file)
    { vendor: permitted[:vendor],
      raw_data: permitted[:file].read,
      filename: permitted[:file].original_filename,
      completed: false, processed_by: current_user,
      existing_customers: 0, new_customers: 0,
      tickets_sold: 0 }
  end
end
