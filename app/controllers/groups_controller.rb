class GroupsController < ApplicationController
  before_filter :is_staff_filter


  def index
    @groups = Group.all
  end

  def show
    @group = Group.find(params[:id])

  end

  def new
    @customers_id = params[:customers]
    if @customers_id.length != 1
      flash[:notice] = "Please select exactly 1 customer to manage groups"
      redirect_to customers_path
    end
    @group = Group.new()

    @customers = @customers_id.map { |x| Customer.find_by_id(x.to_i) }
    @groups = Group.select("id, name, address_line_1, address_line_2, city, state, zip, work_phone, cell_phone, work_fax, group_url, comments")
  end

  def edit
    @group = Group.find(params[:id])
    #single table inheritance causes this weird interaction in params
    if params[:company] != nil
      @group.attributes = params[:company]
    elsif params[:family] != nil
      @group.attributes = params[:family]
    end
    @group.save
    redirect_to groups_path
  end

  def create
    @group = Group.new(params[:group])
    if params[:commit] =~ /create/i
      @customers = params[:customers].map { |x| Customer.find_by_id(x.to_i) }
      @customers.each do |customer|
        @group.customers << customer
      end

    end
    if @group.save
      flash[:notice] = 'You successfully create a group.'
      redirect_to group_path(@group)
    else
      flash[:notice] = 'Sorry, something wrong with your input information.'
      redirect_to new_group_path(:customers => @customers)
    end
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
  def delete_customer
    #params[:merge] contains the ids of the ids of the customers to delete, since i reused a partial

    @group = Group.find(params[:id])
    params[:merge].keys.each do |cust|
      @group.customers.delete(Customer.find(cust))
    end
    redirect_to group_path(@group)
  end
  def add_to_group
    @customers_id = params[:customers]
    @customers = @customers_id.map { |x| Customer.find_by_id(x) }

    if params[:group].nil?
      flash[:alert] = "You haven't selected any groups!"
      redirect_to new_group_path(:customers => @customers)
    else
      @groups_id = params[:group].keys
      @groups = @groups_id.map { |g| Group.find_by_id(g) }
      @groups.each { |group|
        @customers.each { |customer|
          unless customer.groups.include?(group)
            customer.groups << group
          end
        }
      }

      flash[:notice] = 'Customers successfully added to groups.'
      redirect_to customer_path(current_user)
    end
  end
end
