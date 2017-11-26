class AdminIdentityConstraint

  def matches?(request)
    request.query_parameters["callback_type"] == "admin"
  end
end