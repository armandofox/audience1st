class LabelsController < ApplicationController
  before_filter :is_staff_filter

  before_action do
    session[:return_to] ||= params[:return_to]
  end
  
  # GET /labels
  # GET /labels.xml
  def index
    @labels = Label.all
  end

  def create
    @label = Label.create(label_params)
    if @label.errors.empty?
      return_to = session.delete(:return_to)
      redirect_to (return_to || labels_path)
    else
      redirect_to labels_path, :alert => @label.errors.as_html
    end
  end

  def update
    @label = Label.find(params[:id])
    if @label.update_attributes(label_params)
      redirect_to labels_path
    else
      redirect_to labels_path, :alert => @label.errors.as_html
    end
  end

  # DELETE /labels/1
  # DELETE /labels/1.xml
  def destroy
    @label = Label.find(params[:id])
    @label.destroy
    redirect_to labels_path, :notice => "Label '#{@label.name}' was deleted and removed from all customers that had it."
  end

  private

  # Adds Error to the Label instance, referencing 
  # https://api.rubyonrails.org/v6.1.0/classes/ActiveModel/Errors.html#method-i-add
  def label_params
    params.require(:label_name)
    params.permit(:label_name)
    { name: params[:label_name] }
  end
end
