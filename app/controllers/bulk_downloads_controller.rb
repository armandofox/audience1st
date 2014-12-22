class BulkDownloadsController < ApplicationController
  before_filter :is_admin
  
  def index ; redirect_to :action => :new ; end

  def show ; redirect_to :action => :edit ; end
  
  def create
    @download = BulkDownload.create_new(params[:bulk_download])
    if @download.save
      render :action => :edit
    else
      render :action => :new
    end
  end

  def edit
    @download = BulkDownload.find(params[:id])
    if @download.report_names.blank?
      flash[:warning] = "No report names could be retrieved.  Make sure your login and password are correct."
    end
  end

  def update
    @download = BulkDownload.find(params[:id])
    klass = @download.import_class
    begin
      Import.transaction do
        params[:import].keys.reject { |k| params[:import][k].blank? }.each do |key|
          i = klass.send(:new) # create new import of right type
          i.show = find_or_create_show(key)
          data,content_type = @download.get_one_file(key)
          i.set_source_data(data, content_type)
          i.save!
        end
      end
    rescue Exception => e
      flash[:warning] = "Creating new import(s) failed: #{e.message} (#{e.backtrace})"
      redirect_to edit_bulk_download_path(@download) and return
    end
    flash[:warning] = "New imports successfully staged.  Ready to preview and finalize each one."
    redirect_to :controller => :imports, :action => :index
  end

  def destroy
    BulkDownload.find(params[:id]).destroy
    redirect_to :action => :new
  end

  private

  def find_or_create_show(key)
    name = params[:new][key]
    return Show.create_placeholder!(name) if !name.blank?
    show_id = params[:show][key]
    raise "You must select an existing show or enter a new show for every list to be imported." if show_id.blank?
    raise "Show ID #{show_id} not found!" unless (s = Show.find_by_id(show_id))
    s
  end
    
end
