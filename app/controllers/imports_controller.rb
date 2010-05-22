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
    @collection,klass = Import.preview
    case klass
    when Customer
      @template = 'customer/customer'
    else
      flash[:warning] = "Don't know how to preview a collection of #{Inflector.pluralize(klass)}."
      redirect_to :action => :new
    end
  end

end
