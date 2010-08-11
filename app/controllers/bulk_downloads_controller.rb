class BulkDownloadsController < ApplicationController
  before_filter :is_admin
  # verify :method => :post, :only => :create
  # verify :method => :put, :only => :update
  ssl_required                  # since usernames and passwords will be collected
  
  def index ; redirect_to :action => :new ; end

  def create
    @download = BulkDownload.create_new(params[:bulk_download])
    if @download.report_names.nil? || @download.report_names.empty?
      flash[:warning] = "No report names could be retrieved.  Make sure your login and password are correct."
      redirect_to :action => :new
    else
      @download.save!
      render :action => :edit
    end
  end

  def update
    @download = BulkDownload.find(params[:id])
    transaction do
      params[:import].keys.reject { |k| params[:import][k].blank? }.each do |key|
        i = params[:import_class].constantize.send(:new) # create new import of right type
        #file,content_type = 
        i.show = find_or_create_show(params,key)
        
      end
    end
  end

  private

  def find_or_create_show(params,key)
    return Show.create_placeholder!(name) if !(name = params[:new][:key]).blank?
    show_id = params[:show][:key]
    raise "Show ID #{show_id} not found!" unless (s = Show.find_by_id(show_id))
    s
  end
    
end
