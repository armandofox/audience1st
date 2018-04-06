if false

if (Option.sendgrid_key_name.blank? or
    Option.sendgrid_key_value.blank? or
    Option.sendgrid_domain.blank?)
  Rails.application.config.action_mailer.perform_deliveries = false
else
  Rails.application.config.action_mailer.delivery_method = :sendmail
  ActionMailer::Base.smtp_settings = {
    :username => Option.sendgrid_key_name,
    :password => Option.sendgrid_key_value,
    :domain   => Option.sendgrid_domain,
    :address  => 'smtp.sendgrid.net',
    :port     => 587,
    :authentication => :plain,
    :enable_starttls_auto => true
  }
end

  end
