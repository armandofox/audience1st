module AuthenticatedTestHelper
  # Sets the current user in the session from the user fixtures.
  def login_as(user)
    @request.session[:cid] = user ? (user.is_a?(Customer) ? user.id : customers(user).id) : nil
  end

  def authorize_as(user)
    @request.env["HTTP_AUTHORIZATION"] = user ? ActionController::HttpAuthentication::Basic.encode_credentials(customers(user).login, 'monkey') : nil
  end
  
  # rspec
  def mock_user
    user = mock_model(Customer, :id => 1,
      :login  => 'user_name',
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
