class ImportsController < ApplicationController

  before_filter :is_admin

  def new
    @import ||= Import.new
  end

  def create
    type = params[:import][:type]
    @import = (type.constantize).new(params[:import])
    @import.completed = false
    if @import.save
      flash[:notice] = "A preview of what will be imported is below.  Records with errors will not be imported."
      redirect_to edit_import_path(@import)
    else
      render :action => :new
    end
  end

  def edit
    @import = Import.find(params[:id])
    @collection = @import.preview
    if @collection.empty?
      flash[:warning] = "Couldn't find any valid data to import: #{@import.errors.full_messages.join(', ')}.  Try uploading a different file."
      logger.info "Attachment error on #{@import.full_filename}"
      redirect_to(:action => :new) and return
    end
    @num_records = @import.num_records
    unless (@partial = partial_for_collection(@collection))
      flash[:warning] = "Don't know how to preview a collection of #{ActiveSupport::Inflector.pluralize(@collection.first.class.to_s)}."
      redirect_to(:action => :new) and return
    end
  end

  def update
    @import = Import.find(params[:id])
    @imports,@rejects = @import.import!
    flash[:notice] = "#{@imports.length} records successfully imported."
    if @rejects.empty?
      redirect_to imports_path
      @import.destroy
    else
      flash[:notice] <<
        "<br/>The #{@rejects.length} records shown below could not be imported due to errors."
      @collection = @rejects
      @partial = partial_for_collection(@collection)
    end
  end

  def download_invalid
    import = Import.find(params[:id])
    rejects = import.invalid_records
    csv = Customer.to_csv(rejects, :include_errors => true)
    download_to_excel(csv, 'invalid_customers')
    import.destroy
    redirect_to imports_path
  end

  def index
    @imports = Import.find(:all)
    if @imports.empty?
      flash.keep
      redirect_to :action => :new
    end
  end
    
  def destroy
    @import ||= Import.find(params[:id])
    flash[:notice] = "Import of file #{@import.filename} cancelled."
    delete_original_attachment
    @import.destroy
    redirect_to :action => :index
  end

  private

  def delete_original_attachment
    FileUtils.rm_rf @import.full_filename
    logger.info "Deleting #{@import.full_filename}"
  end

  def partial_for_collection(collection)
    case collection.first.class.to_s
    when 'Customer' then 'customers/customer_with_errors'
    end
  end

end
