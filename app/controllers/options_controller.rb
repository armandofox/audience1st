class OptionsController < ApplicationController

  before_filter :is_admin_filter
  
  def options
    @o = Option.first
    return if request.get?
    if (@o.update_attributes(params[:option]))
      flash[:notice] = "Update successful, your changes should take effect in the next 15 minutes."
    else
      flash[:alert] = @o
    end
    redirect_to options_path
  end

  def swipe_test
  end
  
end
