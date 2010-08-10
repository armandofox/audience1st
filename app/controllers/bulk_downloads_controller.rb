class BulkDownloadsController < ApplicationController
  before_filter :is_admin

  def index ; redirect_to :action => :new ; end

  def create
    @download = BulkDownload.create_new(params[:bulk_download])
    if @download.report_names.nil? || @download.report_names.empty?
      flash[:warning] = "No report names could be retrieved.  Make sure your login and password are correct."
      redirect_to :action => :new
    else
      render :action => :edit
    end
  end


end
