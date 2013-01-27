require 'active_merchant'

# are we operating in 'sandbox' mode?  if so, some features like
# "real" CC purchases and email sending are turned off or
# handled differently.
SANDBOX = (RAILS_ENV != 'production'  ||  Option.sandbox?)
if SANDBOX
  ActionMailer::Base.delivery_method = :test
  DISABLE_EMAIL_LIST_INTEGRATION = true
end
