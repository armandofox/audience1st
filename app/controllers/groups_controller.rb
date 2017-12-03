class GroupsController < ApplicationController
  before_filter :is_staff_filter


  def index
    @groups = Group.all
  end

  def show
    @group = Group.find(params[:id])

  end

  def new
    @group = Group.new()
    @customers_id = params[:customers]
    @customers = @customers_id.map { |x| Customer.find_by_id(x.to_i) }
  end

  def edit
    @group = Group.find(params[:id])

    if params[:company] != nil
      @group.attributes = params[:company]
      @group.save
    elsif params[:family] != nil
      @group.attributes = params[:family]
      @group.save
    end

    redirect_to groups_path
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

  end

  def destroy
    @group = Group.find(params[:id])
    @group.destroy
    respond_to do |format|
      format.html { redirect_to groups_path, notice: 'Group was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

end
