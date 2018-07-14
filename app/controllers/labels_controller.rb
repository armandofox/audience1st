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

  # GET /labels/1/edit
  def edit
    @label = Label.find(params[:id])
  end

  # POST /labels
  # POST /labels.xml
  def create
    @label = Label.new(params[:label])
    if @label.save
      return_to = session.delete(:return_to)
      redirect_to return_to, :notice => "Label '#{@label.name}' was successfully created."
    else
      redirect_to labels_path, :alert => @label.errors.as_html
    end
  end

  # PUT /labels/1
  # PUT /labels/1.xml
  def update
    @label = Label.find(params[:id])
    if @label.update_attributes(params[:label])
      return_to = session.delete(:return_to)
      redirect_to return_to, :notice => 'Label was successfully updated.'
    else
      redirect_to edit_label_path(@label), :alert => @label.errors.as_html
    end
  end

  # DELETE /labels/1
  # DELETE /labels/1.xml
  def destroy
    @label = Label.find(params[:id])
    @label.destroy
    return_to = session.delete(:return_to)
    redirect_to return_to, :notice => "Label '#{@label.name}' was deleted and removed from all customers that had it."
  end
end
