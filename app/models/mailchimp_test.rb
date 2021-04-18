class MailchimpTest
  require "MailchimpMarketing"

  mailchimp = MailchimpMarketing::Client.new
  mailchimp.set_config({
  	:api_key => ENV["b17730e9d2edfef89ae9db104dfc2ebe-us1"],
  	:server => ENV["us1"]
  })
end