class OptionsController < ApplicationController

  before_filter :is_admin_filter

  def index
    redirect_to :action => 'edit'
  end

  def edit
    @vars = Option.find(:all).group_by(&:group)
    return if request.get?
    # update config variables
    msgs = []
    params[:values].each_pair do |var,val|
      begin
        o = Option.find_by_name(var)
        o.value = val
        o.save!                 # don't use update_attribute since we want validation
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
