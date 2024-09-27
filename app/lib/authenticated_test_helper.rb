module AuthenticatedTestHelper
  def login_as_boxoffice_manager
    login_as(create(:boxoffice_manager))
  end
  def login_as(user)
    if user
      session[:cid] = user.id
    else
      @request.session[:cid] = @current_user = nil
    end
  end

  def authorize_as(user)
    @request.env["HTTP_AUTHORIZATION"] = user ? ActionController::HttpAuthentication::Basic.encode_credentials(customers(user).email, 'monkey') : nil
  end
  
end
