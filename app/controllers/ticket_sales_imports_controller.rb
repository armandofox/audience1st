class TicketSalesImportsController < ApplicationController

  before_filter :is_boxoffice_filter

  # View all imports, also provides a form to create a new import by uploading a file.
  # The view provides a dropdown populated from TicketSalesImporter::IMPORTERS, which
  # should be used to set the 'vendor' field of the import.
  def index
    @ticket_sales_imports = TicketSalesImport.all.sorted
    @vendors = TicketSalesImport::IMPORTERS
  end

  # upload: grab uploaded data, create a new TicketSalesImport instance whose 'vendor'
  # field is populated from the dropdown on the index page and whose 'raw_data' is populated
  # from the contents of the uploaded file

  def create
    @import = TicketSalesImport.new(
      :vendor => params[:vendor], :raw_data => params[:file].read,:processed_by => current_user)
    begin
      @import.save!
      redirect_to edit_ticket_sales_import_path(@import)
    rescue ActiveRecord::RecordInvalid
      redirect_to ticket_sales_imports_path, :alert => @import.errors.as_html
    end
  end

  def edit
    @import = TicketSalesImport.find params[:id]
    @import.parse
    if @import.errors.empty?
      render :action => 'edit'
    else
      redirect_to ticket_sales_imports_path, :alert => @import.errors.as_html
    end
  end

  # Finalize the import according to dropdown menu selections
  def update
    import = TicketSalesImport.find params[:id]
    order_hash = params[:o]
    # each hash key is the id of a saved (but not finalized) order
    # each hash value is {:action => a, :customer_id => c, :first => f, :last => l, :email => e}
    #  if action is ALREADY_IMPORTED or DO_NOT_IMPORT, do nothing
    #  if action is CREATE_NEW_CUSTOMER, create new customer & finalize order
    #  if action is USE_EXISTING_CUSTOMER, attach given customer ID & finalize order
    Order.transaction do
      order_hash.each_pair do |order_id, o|
        order = Order.find order_id
        case o[:action]
        when ImportableOrder::CREATE_NEW_CUSTOMER
          order.customer = order.purchaser =
            Customer.new(:first_name => o[:first], :last_name => o[:last], :email => o[:email])
          customer.force_valid = true
          order.finalize!
          import.new_customers += 1
        when ImportableOrder::USE_EXISTING_CUSTOMER
          order.customer_id = order.purchaser_id = o[:customer_id]
          order.finalize!
          import.existing_customers += 1
        when ImportableOrder::DO_NOT_IMPORT, ImportableOrder::ALREADY_IMPORTED
        end
      end
      import.save!
    end
  end

end
