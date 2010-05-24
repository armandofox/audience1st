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
      flash[:notice] = "File #{@import.filename} was successfully uploaded.  A preview of what will be imported is below.  If it looks good, click Finalize Import to proceed."
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
    @partial =
      case @collection.first.class.to_s
      when 'Customer' then 'customers/customer'
      else
        flash[:warning] = "Don't know how to preview a collection of #{ActiveSupport::Inflector.pluralize(@collection.first.class.to_s)}."
        redirect_to(:action => :new) and return
      end
  end

  def update
    @import = Import.find(params[:id])
    @imports,@rejects = @import.import!
  end

  def index
    @imports = Import.find(:all)
    if @imports.empty?
      flash.keep
      redirect_to :action => :new
    end
  end
    
  def destroy
    @import = Import.find(params[:id])
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
  
end
