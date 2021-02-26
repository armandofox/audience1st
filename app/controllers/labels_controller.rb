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
    if @label.update_attributes(:name => params[:label_name])
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

  def label_params
    params.permit(:label_name)
    { :name => params[:label_name] }
  end
end
