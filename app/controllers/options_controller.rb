class OptionsController < ApplicationController

  before_filter :is_admin_filter
  
  def options
    @o = Option.first
    return if request.get?
    if (@o.update_attributes(option_params))
      flash[:notice] = "Update successful, your changes should take effect in the next 15 minutes."
    else
      flash[:alert] = @o
    end
    redirect_to options_path
  end

  def swipe_test
  end

  private

  def option_params
    forbidden_fields = %w(id created_at updated_at venue_id venue_shortname)
    fields = Option.columns.map(&:name) - forbidden_fields
    params.require(:option).permit(fields)
  end
end
