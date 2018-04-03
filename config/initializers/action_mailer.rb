# Specifies the header that your server uses for sending files.
# config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
# config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

Rails.application.config.action_mailer.delivery_method = :sendmail
ActionMailer::Base.smtp_settings = {
  :username => 'audience1st_production',
  :password => Figaro.env.sendgrid_api_key_value!,
  :domain   => Figaro.env.sendgrid_domain!,
  :address  => 'smtp.sendgrid.net',
  :port     => 587,
  :authentication => :plain,
  :enable_starttls_auto => true
}

