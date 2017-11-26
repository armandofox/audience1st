class CustomerIdentityConstraint

  def matches?(request)
    request.query_parameters["callback_type"] == "customer"
  end
end