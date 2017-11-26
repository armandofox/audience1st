class LoginIdentityConstraint

  def matches?(request)
    request.query_parameters["callback_type"] == "login"
  end
end