class ImportsController < ApplicationController

  before_filter :is_admin

  def new
    @import = Import.new
  end

  def create
    @import = Import.new(params[:import])
    @import.completed = false
    if @import.save
      flash[:notice] = "File #{h(@import.filename)} was successfully uploaded."
      redirect_to edit_import_path(@import)
    else
      render :action => new
    end
  end

  def edit
    @import = Import.find(params[:id])
    @collection,klass = @import.preview
    @partial =
      case klass.to_s
      when 'Customer' then 'customer/customer'
      else
        flash[:warning] = "Don't know how to preview a collection of #{ActiveSupport::Inflector.pluralize(klass.to_s)}."
        redirect_to :action => :new
        nil
      end
  end

end
