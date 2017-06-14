class LabelsController < ApplicationController
  before_filter :is_staff_filter
  # GET /labels
  # GET /labels.xml
  def index
    @labels = Label.all
  end

  # GET /labels/new
  # GET /labels/new.xml
  def new
    @label = Label.new
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
      next_action = (params[:commit] =~ /another/i ? new_label_path : labels_path)
      redirect_with next_action, :notice => 'Label was successfully created.'
    else
      flash[:alert] = ['Creating label failed: ', @label]
      render :action => "new"
    end
  end

  # PUT /labels/1
  # PUT /labels/1.xml
  def update
    @label = Label.find(params[:id])
    if @label.update_attributes(params[:label])
      redirect_with(@label, :notice => 'Label was successfully updated.')
    else
      flash[:alert] = ['Editing label failed: ', @label]
      render :action => "edit"
    end
  end

  # DELETE /labels/1
  # DELETE /labels/1.xml
  def destroy
    @label = Label.find(params[:id])
    @label.destroy
    redirect_to labels_path
  end
end
