class OptionsController < ApplicationController

  before_filter :is_admin_filter
  
  def index
    @o = Option.first
  end

  def update
    @o = Option.first
    if (@o.update_attributes(params['option']))
      flash[:notice] = "Update successful, your changes should take effect in the next 15 minutes."
    else
      flash[:alert] = @o.errors.as_html
    end
    redirect_to options_path
  end

end
