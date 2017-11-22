Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer
  provider :identity, on_failed_registration: lambda { |env|
    IdentitiesController.action(:new).call(env)
  }, model: Authorization, locate_conditions: lambda{|req| {model.auth_key => req['email']}}
end