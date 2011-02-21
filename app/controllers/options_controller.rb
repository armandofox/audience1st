class OptionsController < ApplicationController

  before_filter :is_admin_filter

  def index
    redirect_to :action => 'edit'
  end

  def edit
    @vars = Option.find(:all, :conditions => "grp != \"Config\"").group_by(&:grp)
    return if request.get?
    # update config variables
    msgs = []
    params[:values].each_pair do |var,val|
      begin
        o.set_value!(var,val)
      rescue Exception => e
        msgs << "Error: #{e.message}"
      end
    end
    unless msgs.empty?
      flash[:notice] = msgs.join("<br/>")
      redirect_to :action => 'edit', :method => 'get'
    else
      flash[:notice] = "Update successful, your changes should take effect in the next 15 minutes"
      redirect_to :controller => 'customers', :action => 'welcome'
    end
  end

end
