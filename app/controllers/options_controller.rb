class OptionsController < ApplicationController

  before_filter :is_admin_filter
  ssl_required
  
  def index
    redirect_to :action => 'edit'
  end

  def edit
    @o = Option.first
  end

  def update
    @o = Option.first
    if (@o.update_attributes(params[:option]))
      flash[:notice] = "Update successful, your changes should take effect in the next 15 minutes."
    else
      flash[:warning] = @o.errors.full_messages.join(", ")
    end
    redirect_to :action => :edit
  end
end
