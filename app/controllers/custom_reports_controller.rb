class CustomReportsController < ApplicationController

  before_filter :is_boxoffice_manager_filter
  
  scaffold :custom_report

  def new
    @custom_report = CustomReport.new
    @sql = @custom_report.render_sql
    @show_names = Show.find_all
    @vouchertypes =
      Vouchertype.find(:all, :conditions => ["is_bundle = ?", false])
    @bundle_vouchertypes =
      Vouchertype.find(:all, :conditions => ["is_bundle = ?", true])
    return unless params[:commit]
  end

  def edit
    unless (@custom_report = CustomReport.find_by_id(params[:id]))
      flash[:notice] = "No custom report found"
      redirect_to :action => 'list'
      return
    end
    render :action => 'new'
  end

  def create
    @custom_report = CustomReport.new(params[:custom_report])
    gather_params
    if @custom_report.save
      flash[:notice] = "New custom report saved"
      redirect_to :action => 'list'
    else
      flash[:warning] = @custom_report.errors.full_messages
      redirect_to :action => 'new'
    end
  end

  private

  def gather_params
    @custom_report ||= CustomReport.new
    @custom_report.clear_all_clauses
    @custom_report.clear_all_fields
    # gather criteria
    params[:use].keys.each do |k|
      @custom_report.add_clause(k, params.select { |x,v| x.match /^#{k}\b/ })
    end
    params[:select][:customers].each_key do |k|
      @custom_report.add_field(k)
    end
  end
end
