class GroupsController < ApplicationController
  before_filter :is_staff_filter

  def validate_one_customer
    @customer_id = params[:customers]
    if @customer_id.length != 1
      flash[:notice] = "Please select exactly 1 customer to manage what groups they are in"
      redirect_to customers_path
      return
    end
  end
  def index
    @groups = Group.all
  end

  def show
    @group = Group.find(params[:id])

  end

  #manage groups
  def new
    @group = Group.new()
    @customer = Customer.find(@customer_id.first)
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
    return
  end

  def create
    @group = Group.new(params[:group])
      @customer = Customer.find(params[:customer])
      @group.customers << @customer
      if @group.save
        flash[:notice] = 'You successfully create a group.'
        redirect_to group_path(@group)
      else
        flash[:notice] = 'Sorry, something wrong with your input information.'
        redirect_to new_group_path(:customers => [@customer])
        return
      end
  end

  def update_customer_groups
    customer_id = params[:customer]
    customer = Customer.find(customer_id)
    customer.groups.delete_all
    if !params[:group].nil?
      params[:group].keys.each do |group_id|
        customer.groups <<  Group.find(group_id)
      end
    end
    flash[:notice] = "Successfully updated groups"
    redirect_to customer_path(customer_id)
    return


  end

  def destroy
    @group = Group.find(params[:id])
    @group.destroy
    flash[:notice] = "Group was successfully destroyed."
    redirect_to groups_path
    return
  end
  def delete_customer
    @group = Group.find(params[:id])
    #params[:merge] contains the ids of the ids of the customers to delete, since i reused a partial
    if params[:merge].nil?
      flash[:notice] = "No Customers Selected"
      redirect_to group_path(@group)
      return
    end
    params[:merge].keys.each do |cust|
      @group.customers.delete(Customer.find(cust))
    end
    redirect_to group_path(@group)
    return
  end
  def add_to_group
    validate_one_customer()
    @customer = Customer.find(@customer_id)
    if params[:group].nil?
      flash[:alert] = "You haven't selected any groups!"
      redirect_to new_group_path(:customers => [@customer])
      return
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
      flash[:notice] = 'Successfully updated groups.'
      redirect_to customer_path(current_user)
      return
    end
  end
end
