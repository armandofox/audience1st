class GroupsController < ApplicationController
  before_action :set_group, only: [:show, :edit, :update, :destroy]
  before_filter :is_staff_filter


  def index
    @groups = Group.all
  end

  def show
  end

  def new
    @group = Group.new()
    @customers_id = params[:customers]
    @customers = @customers_id.map { |x| Customer.find_by_id(x.to_i) }
  end

  def edit
  end

  def create
    @group = Group.new(params[:group])
    if params[:commit] =~ /create/i
      @customers = params[:customers].strip.split(" ").map { |x| Customer.find_by_id(x.to_i) }
      @customers.each do |customer|
        @group.customers << customer
      end
    end
    @group.save
    redirect_to customer_path(current_user)
  end

  def update
    respond_to do |format|
      if @group.update(group_params)
        format.html { redirect_to @group, notice: 'Group was successfully updated.' }
        format.json { render :show, status: :ok, location: @group }
      else
        format.html { render :edit }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @group.destroy
    respond_to do |format|
      format.html { redirect_to groups_url, notice: 'Group was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

end
