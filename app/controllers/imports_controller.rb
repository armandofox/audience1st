class ImportsController < ApplicationController
  include ActiveSupport::Inflector
  before_filter :is_admin
  verify :method => :post, :only => :create
  verify :method => :put, :only => :update
  verify :method => :delete, :only => :destroy

  def new
    @import ||= Import.new
  end

  def create
    redirect_to :action => :new and return unless params[:import]
    type = params[:import][:type]
    @import = (type.constantize).new(params[:import])
    if !(new = params[:new_show_name]).blank?
      if Show.find_by_name(new)
        flash[:warning] = "Show \"#{new}\" already exists."
        redirect_to :action => :new and return
      end
      @import.show = Show.create_placeholder!(new)
    end
    if @import.save
      flash[:notice] = "A preview of what will be imported is below.  Records with errors will not be imported.  Click Continue Import to import non-error records and ignore records with errors, or click Cancel Import to do nothing."
      redirect_to edit_import_path(@import)
    else
      render :action => :new
    end
  end

  def show ; redirect_to :action => :index ; end

  def edit
    @import = Import.find(params[:id])
    @collection = @import.preview
    if (@partial = partial_for_import(@import)).nil?
      flash[:warning] = "Don't know how to preview a collection of #{ActiveSupport::Inflector.pluralize(@import.class.to_s)}."
      redirect_to(:action => :new) and return
    end
  end

  def update
    @import = Import.find(params[:id])
    @imports,@rejects = @import.import!
    render(:action => :new) and return if !@import.errors.empty?
    flash[:notice] = "#{@imports.length} records successfully imported."
    @import.update_attributes(
      :completed_at => Time.now,
      :number_of_records => @imports.length,
      :completed_by_id => logged_in_id)
    if @rejects.empty?
      redirect_to imports_path
    else
      flash[:notice] <<
        "<br/>The #{@rejects.length} records shown below could not be imported due to errors."
      @collection = @rejects
      @partial = partial_for_import(@import)
    end
  end

  def download_invalid
    import = Import.find(params[:id])
    rejects = import.invalid_records
    csv = Customer.to_csv(rejects, :include_errors => true)
    download_to_excel(csv, 'invalid_customers')
    import.destroy
  end

  def index
    @imports = Import.find(:all)
    if @imports.empty?
      flash.keep
      redirect_to :action => :new
    end
  end

  def help
    # return a partial displaying help for the selected import type
    render :partial => ['imports/', singularize(tableize(params[:value])), '_help'].join
  end
  
  def destroy
    @import ||= Import.find(params[:id])
    flash[:notice] = "Import of file #{@import.filename} cancelled."
    delete_original_attachment
    @import.destroy rescue nil
    redirect_to :action => :index
  end

  private

  def delete_original_attachment
    begin
      FileUtils.rm_rf @import.full_filename
      logger.info "Deleting #{@import.full_filename}"
    rescue Exception => e
      logger.info "Deleting original attachment for import ID #{@import.id}: #{e.message}"
    end
  end

  def partial_for_import(import)
    case import.class.to_s
    when 'CustomerImport' then 'customers/customer_with_errors'
    when 'BrownPaperTicketsImport', 'TBAWebtixImport' then 'external_ticket_orders/external_ticket_order'
    end
  end

end
