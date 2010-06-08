module AuthenticatedTestHelper
  # Sets the current user in the session from the user fixtures.
  def login_as(user)
    if user
      user = customers(user) unless user.kind_of?(Customer)
      @request.session[:cid] = user.id
      @current_user = user
    else
      @request.session[:cid] = @current_user = nil
    end
  end

  def authorize_as(user)
    @request.env["HTTP_AUTHORIZATION"] = user ? ActionController::HttpAuthentication::Basic.encode_credentials(customers(user).email, 'monkey') : nil
  end
  
  # rspec
  def mock_user
    user = mock_model(Customer, :id => 1,
      :email  => 'user_name@email.com',
      :first_name   => 'User',
      :last_name => 'Surname',
      :to_xml => "Customer-in-XML", :to_json => "Customer-in-JSON", 
      :errors => [],
      :is_staff => nil,
      :subscriber? => nil)
    user.stub(:update_attribute)
    user
  end  
end
