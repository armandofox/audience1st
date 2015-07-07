# are we operating in 'sandbox' mode?  if so, some features like
# "real" CC purchases and email sending are turned off or
# handled differently.
SANDBOX = (Figaro.env['sandbox'] == 'true')
if SANDBOX
  ActionMailer::Base.delivery_method = :test
  Figaro.env['email_integration'] = ''
end
