class OptionsController < ApplicationController

  before_filter :is_admin_filter
  
  def edit
    @o = Option.first
  end

  def update
    @o = Option.first
    if (@o.update_attributes(params[:option]))
      flash[:notice] = "Update successful, your changes should take effect in the next 15 minutes."
    else
      flash[:alert] = @o
    end
    redirect_to :action => :edit
  end
end
